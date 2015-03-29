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
import SocketServer
import dns.resolver

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
        if code in ('PERM','TIMEOUT','NOTFOUND','OK','TEMP'):
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



class TlsPolicy(Handler):

    domain   = None
    resolver = dns.resolver.Resolver()

    # is called by handle()
    def _handle_tls_policy(self,key):
        return TlsPolicy.resolve_and_map(key)

    @staticmethod
    def map(txt):
        data = dict(s.split('=') for s in txt.split(" "))

        if "certificate" in data:
            certificate = data["certificate"].split(",")
            if "trusted" in certificate:
                if "match-domain" in certificate:
                    return "secure"
                if "match-mx" in certificate:
                    return "verify"

        if data["starttls"]=="true":
            return "encrypt"
        else:
            return "may"

    @staticmethod
    def resolve_and_map(nexthop):
        try:
            query   = "%s.%s" % (nexthop, TlsPolicy.domain)
            answers = TlsPolicy.resolver.query(query,'TXT')

            return TlsPolicy.map(answers[0].strings[0])

        except dns.exception.Timeout:
            raise MapError('TIMEOUT', '')
        except dns.resolver.NoAnswer:
            raise MapError('NOTFOUND', '')
        except dns.resolver.NoNameservers:
            raise MapError('TEMP', '')


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='TLS Policy Map daemon using the socketmap protocol')
    parser.add_argument('--socket',     help='path to unix socket', default="/var/run/tls_policy.sock")
    parser.add_argument('--domain',     help='domain for lookups',  default="tls-scan.informatik.uni-bremen.de")
    parser.add_argument('--nameserver', help='nameserver to query', default="134.102.201.91")

    args = parser.parse_args()

    # Set options
    TlsPolicy.resolver.nameservers = [args.nameserver]
    TlsPolicy.domain               = args.domain

    # Start server
    Daemon(args.socket,TlsPolicy).run()

