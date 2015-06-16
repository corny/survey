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

  DEFAULT_POLICY = "may"

  def __init__(self, domain=None, mxResolver=None, txtResolver=None, pinning='never', maxage=None, dane=True):
    self.domain      = domain
    self.pinning     = pinning
    self.maxage      = maxage
    self.dane        = dane
    self.mxResolver  = dns.resolver.Resolver()
    self.txtResolver = dns.resolver.Resolver()

    if txtResolver:
      self.txtResolver.nameservers = txtResolver.split(",")
    if mxResolver:
      self.mxResolver.nameservers  = mxResolver.split(",")

  def map(self, txt_records):
      # Ignore empty txt records (unreachable hosts)
      txt_records  = filter(None, txt_records)
      notBefore    = (time.time() - self.maxage) if self.maxage != None else None
      fingerprints = []
      errors       = []

      # Always return 'may' if none are reachable
      if len(txt_records) == 0:
          return self.DEFAULT_POLICY

      for txt in txt_records:
        # Convert key value pairs into a dictionary
        data = dict(s.split('=',2) for s in txt.split(" "))

        if data["starttls"] != "true":
            return self.DEFAULT_POLICY

        # Entry outdated?
        if notBefore and int(data['updated']) < notBefore:
            return self.DEFAULT_POLICY

        # Add fingerprint to list
        if "fingerprint" in data:
            fingerprints.extend(data["fingerprint"].split(","))

        # TODO respect all records
        if "certificate-problems" in data:
            errors = True

      if (self.pinning=='always' or (errors and self.pinning=='on-errors')) and len(fingerprints) > 0:
        return "fingerprint " + " ".join(["match="+fp for fp in fingerprints])

      if errors:
        return "encrypt"
      else:
        return "verify"


  def resolve_and_map(self, nexthop):
      try:
          # Query MX records
          mx_records  = self.mxResolver.query(nexthop,'MX')
          txt_records = []

          # Query TXT records for the MX records
          for mx in mx_records:
              if self.dane:
                  try:
                      # Check for TLSA mx_records
                      self.mxResolver.query('_25._tcp.' + mx.exchange, 'TLSA')
                      return "dane-only"
                  except dns.resolver.NXDOMAIN:
                      None

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
    parser.add_argument('--socket',       help='Path to unix socket', default="/var/run/tlspolicy.sock")
    parser.add_argument('--domain',       help='Domain for lookups',  default="tls-scan.informatik.uni-bremen.de")
    parser.add_argument('--fingerprints', help='Use certificate pinning with fingerprints', default='always', choices=['always', 'on-problems', 'never'])
    parser.add_argument('--mxresolver',   help='Nameserver for MX and TLSA lookups',  default="")
    parser.add_argument('--txtresolver',  help='Nameserver for TXT lookups', default="134.102.201.91")
    parser.add_argument('--maxage',       help='Maximum age of TXT records in seconds', type=int)
    parser.add_argument('--dane',         help='Enforce DANE if TLSA records exists', default='true', choices=['true','false'])
    args = parser.parse_args()

    # Set options
    TlsPolicyHandler.tlsPolicy = TlsPolicyMap(
      domain      = args.domain,
      pinning     = args.pinning,
      mxResolver  = args.mxresolver,
      txtResolver = args.txtresolver,
      maxage      = args.maxage,
      dane        = args.dane=="true",
    )

    # Start server
    Daemon(args.socket,TlsPolicyHandler).run()

