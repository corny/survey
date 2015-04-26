#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-dnspython
#
# MapError and Handler class taken from:
# http://pydoc.net/Python/pysrs/0.30.11/SocketMap/
# Copyright: 2004 Shevek
#            2004-2010 Business Management Systems
# License: PSF-2.4


import argparse
import os
import time
import dns.resolver
import SocketServer

class MapError(Exception):
  def __init__(self,code,reason):
    self.code   = code
    self.reason = reason

class Handler(SocketServer.StreamRequestHandler):

  def write(self,s):
    "write netstring to socket"
    self.wfile.write('%d:%s,' % (len(s),s))
    print(s)

  def _readlen(self,maxlen=8):
    "read netstring length from socket"
    n = ""
    file = self.rfile
    ch = file.read(1)
    while ch != ":":
      if not ch:
        raise EOFError
      if not ch in "0123456789":
        raise ValueError
      if len(n) >= maxlen:
        raise OverflowError
      n += ch
      ch = file.read(1)
    return int(n)

  def read(self, maxlen=None):
    "Read a netstring from the socket, and return the extracted netstring."
    n = self._readlen()
    if maxlen and n > maxlen:
      raise OverflowError
    file = self.rfile
    s = file.read(n)
    ch = file.read(1)
    if ch == ',':
      return s
    if ch == "":
      raise EOFError
    raise ValueError

  def handle(self):
    #print("connect")
    while True:
      try:
        line = self.read()
        args = line.split(' ',1)
        map  = args.pop(0).replace('-','_')
        meth = getattr(self, '_handle_' + map, None)
        if not meth:
          raise ValueError("Unrecognized map: %s" % map)

        res = meth(*args)
        self.write('OK ' + res)
      except EOFError:
        #print("Ending connection")
        return
      except MapError,x:
        if x.code in ('PERM','TIMEOUT','NOTFOUND','OK','TEMP'):
          self.write("%s %s"%(x.code,x.reason))
        else:
          self.write("%s %s %s"%('PERM',x.code,x.reason))
      except LookupError,x:
        self.write("NOTFOUND")
      except Exception,x:
        #print x
        self.write("TEMP %s"%x)


class Daemon(object):

  def __init__(self,socket,handlerfactory):
    self.socket = socket
    try:
      os.unlink(socket)
    except: pass
    self.server = SocketServer.ThreadingUnixStreamServer(socket,handlerfactory)
    self.server.daemon = self

  def run(self):
    self.server.serve_forever()



class TlsPolicyHandler(Handler):
  policyMap = None

  # is called by handle()
  def _handle_tlspolicy(self,key):
      return self.policyMap.resolve_and_map(key)



class TlsPolicyMap(Handler):

  def __init__(self, domain=None, mxResolver=None, txtResolver=None, certPinning=False, notBefore=None):
    self.domain       = domain
    self.certPinning  = certPinning
    self.notBefore    = notBefore
    self.mxResolver   = dns.resolver.Resolver()
    self.txtResolver  = dns.resolver.Resolver()

    if txtResolver:
      self.txtResolver.nameservers = txtResolver.split(",")
    if mxResolver:
      self.mxResolver.nameservers  = mxResolver.split(",")

  def map(self,txt_records):
      fingerprints = []

      # Ignore empty txt records (unreachable hosts)
      txt_records = filter(None, txt_records)

      # Always return 'may' if none are reachable
      if len(txt_records) == 0:
          return "may"

      for txt in txt_records:
        # Convert key value pairs into a dict
        data = dict(s.split('=',2) for s in txt.split(" "))

        if data["starttls"] != "true":
            return "may"

        # Entry outdated?
        if self.notBefore and int(data['updated']) < self.notBefore:
            return "may"

        if "fingerprint" in data:
            fingerprints.extend(data["fingerprint"].split(","))

        # TODO respect all records
        if "certificate" in data:
            certificate = data["certificate"].split(",")
            if "trusted" in certificate:
                if "match-domain" in certificate:
                    return "secure"
                if "match-mx" in certificate:
                    return "verify"

      if self.certPinning and len(fingerprints) > 0:
        return "fingerprint " + " ".join(["match="+fp for fp in fingerprints])

      return "encrypt"

  def resolve_and_map(self,nexthop):
      try:
          # Query MX records
          mx_records  = self.mxResolver.query(nexthop,'MX')
          txt_records = []

          # Query TXT records for the MX records
          for mx in mx_records:
              query   = "%s%s" % (mx.exchange, self.domain)
              answers = self.txtResolver.query(query,'TXT')
              txt_records.append("".join(answers[0].strings))

          # Map TXT records to TLS policy
          return self.map(txt_records)

      # In case of other results than "OK" postfix does a second
      # lookup for the parent domain.
      # i.e. example.com leads to a seconds lookup for .com
      # This can be avoided by returning "OK"
      except dns.exception.Timeout:
          return "may"
      except dns.resolver.NoNameservers:
          return "may"
      except dns.resolver.NXDOMAIN:
          return "may"
      except dns.resolver.NoAnswer:
          return "may"


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='TLS Policy Map daemon using the socketmap protocol')
    parser.add_argument('--socket',      help='path to unix socket', default="/var/run/tlspolicy.sock")
    parser.add_argument('--domain',      help='domain for lookups',  default="tls-scan.informatik.uni-bremen.de")
    parser.add_argument('--pinning',     help='use certificate pinning with fingerprints', action='store_true', default=False)
    parser.add_argument('--mxresolver',  help='nameserver for MX lookups',  default="")
    parser.add_argument('--txtresolver', help='nameserver for TXT lookups', default="134.102.201.91")
    parser.add_argument('--maxage',      help='maximum age of TXT records in seconds', type=int)
    args = parser.parse_args()

    if args.maxage != None:
      notBefore = time.time() - args.maxage
    else:
      notBefore = None

    # Set options
    TlsPolicyHandler.tlsPolicy = TlsPolicyMap(
      domain      = args.domain,
      mxResolver  = args.mxresolver,
      txtResolver = args.txtresolver,
      certPinning = args.pinning,
      notBefore   = notBefore
    )

    # Start server
    Daemon(args.socket,TlsPolicyHandler).run()

