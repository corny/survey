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
import re
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
  TLS_VERSIONS = {
    769: "TLSv1.0,TLSv1.1,TLSv1.2",
    770: "TLSv1.1,TLSv1.2",
    771: "TLSv1.2",
  }

  # source: https://www.iana.org/assignments/tls-parameters/tls-parameters-4.csv (2015-06-30)
  CIPHERS = {
    "0001": "RSA_WITH_NULL_MD5",
    "0002": "RSA_WITH_NULL_SHA",
    "0003": "RSA_EXPORT_WITH_RC4_40_MD5",
    "0004": "RSA_WITH_RC4_128_MD5",
    "0005": "RSA_WITH_RC4_128_SHA",
    "0006": "RSA_EXPORT_WITH_RC2_CBC_40_MD5",
    "0007": "RSA_WITH_IDEA_CBC_SHA",
    "0008": "RSA_EXPORT_WITH_DES40_CBC_SHA",
    "0009": "RSA_WITH_DES_CBC_SHA",
    "000a": "RSA_WITH_3DES_EDE_CBC_SHA",
    "000b": "DH_DSS_EXPORT_WITH_DES40_CBC_SHA",
    "000c": "DH_DSS_WITH_DES_CBC_SHA",
    "000d": "DH_DSS_WITH_3DES_EDE_CBC_SHA",
    "000e": "DH_RSA_EXPORT_WITH_DES40_CBC_SHA",
    "000f": "DH_RSA_WITH_DES_CBC_SHA",
    "0010": "DH_RSA_WITH_3DES_EDE_CBC_SHA",
    "0011": "DHE_DSS_EXPORT_WITH_DES40_CBC_SHA",
    "0012": "DHE_DSS_WITH_DES_CBC_SHA",
    "0013": "DHE_DSS_WITH_3DES_EDE_CBC_SHA",
    "0014": "DHE_RSA_EXPORT_WITH_DES40_CBC_SHA",
    "0015": "DHE_RSA_WITH_DES_CBC_SHA",
    "0016": "DHE_RSA_WITH_3DES_EDE_CBC_SHA",
    "0017": "DH_anon_EXPORT_WITH_RC4_40_MD5",
    "0018": "DH_anon_WITH_RC4_128_MD5",
    "0019": "DH_anon_EXPORT_WITH_DES40_CBC_SHA",
    "001a": "DH_anon_WITH_DES_CBC_SHA",
    "001b": "DH_anon_WITH_3DES_EDE_CBC_SHA",
    "001e": "KRB5_WITH_DES_CBC_SHA",
    "001f": "KRB5_WITH_3DES_EDE_CBC_SHA",
    "0020": "KRB5_WITH_RC4_128_SHA",
    "0021": "KRB5_WITH_IDEA_CBC_SHA",
    "0022": "KRB5_WITH_DES_CBC_MD5",
    "0023": "KRB5_WITH_3DES_EDE_CBC_MD5",
    "0024": "KRB5_WITH_RC4_128_MD5",
    "0025": "KRB5_WITH_IDEA_CBC_MD5",
    "0026": "KRB5_EXPORT_WITH_DES_CBC_40_SHA",
    "0027": "KRB5_EXPORT_WITH_RC2_CBC_40_SHA",
    "0028": "KRB5_EXPORT_WITH_RC4_40_SHA",
    "0029": "KRB5_EXPORT_WITH_DES_CBC_40_MD5",
    "002a": "KRB5_EXPORT_WITH_RC2_CBC_40_MD5",
    "002b": "KRB5_EXPORT_WITH_RC4_40_MD5",
    "002c": "PSK_WITH_NULL_SHA",
    "002d": "DHE_PSK_WITH_NULL_SHA",
    "002e": "RSA_PSK_WITH_NULL_SHA",
    "002f": "RSA_WITH_AES_128_CBC_SHA",
    "0030": "DH_DSS_WITH_AES_128_CBC_SHA",
    "0031": "DH_RSA_WITH_AES_128_CBC_SHA",
    "0032": "DHE_DSS_WITH_AES_128_CBC_SHA",
    "0033": "DHE_RSA_WITH_AES_128_CBC_SHA",
    "0034": "DH_anon_WITH_AES_128_CBC_SHA",
    "0035": "RSA_WITH_AES_256_CBC_SHA",
    "0036": "DH_DSS_WITH_AES_256_CBC_SHA",
    "0037": "DH_RSA_WITH_AES_256_CBC_SHA",
    "0038": "DHE_DSS_WITH_AES_256_CBC_SHA",
    "0039": "DHE_RSA_WITH_AES_256_CBC_SHA",
    "003a": "DH_anon_WITH_AES_256_CBC_SHA",
    "003b": "RSA_WITH_NULL_SHA256",
    "003c": "RSA_WITH_AES_128_CBC_SHA256",
    "003d": "RSA_WITH_AES_256_CBC_SHA256",
    "003e": "DH_DSS_WITH_AES_128_CBC_SHA256",
    "003f": "DH_RSA_WITH_AES_128_CBC_SHA256",
    "0040": "DHE_DSS_WITH_AES_128_CBC_SHA256",
    "0041": "RSA_WITH_CAMELLIA_128_CBC_SHA",
    "0042": "DH_DSS_WITH_CAMELLIA_128_CBC_SHA",
    "0043": "DH_RSA_WITH_CAMELLIA_128_CBC_SHA",
    "0044": "DHE_DSS_WITH_CAMELLIA_128_CBC_SHA",
    "0045": "DHE_RSA_WITH_CAMELLIA_128_CBC_SHA",
    "0046": "DH_anon_WITH_CAMELLIA_128_CBC_SHA",
    "0067": "DHE_RSA_WITH_AES_128_CBC_SHA256",
    "0068": "DH_DSS_WITH_AES_256_CBC_SHA256",
    "0069": "DH_RSA_WITH_AES_256_CBC_SHA256",
    "006a": "DHE_DSS_WITH_AES_256_CBC_SHA256",
    "006b": "DHE_RSA_WITH_AES_256_CBC_SHA256",
    "006c": "DH_anon_WITH_AES_128_CBC_SHA256",
    "006d": "DH_anon_WITH_AES_256_CBC_SHA256",
    "0084": "RSA_WITH_CAMELLIA_256_CBC_SHA",
    "0085": "DH_DSS_WITH_CAMELLIA_256_CBC_SHA",
    "0086": "DH_RSA_WITH_CAMELLIA_256_CBC_SHA",
    "0087": "DHE_DSS_WITH_CAMELLIA_256_CBC_SHA",
    "0088": "DHE_RSA_WITH_CAMELLIA_256_CBC_SHA",
    "0089": "DH_anon_WITH_CAMELLIA_256_CBC_SHA",
    "008a": "PSK_WITH_RC4_128_SHA",
    "008b": "PSK_WITH_3DES_EDE_CBC_SHA",
    "008c": "PSK_WITH_AES_128_CBC_SHA",
    "008d": "PSK_WITH_AES_256_CBC_SHA",
    "008e": "DHE_PSK_WITH_RC4_128_SHA",
    "008f": "DHE_PSK_WITH_3DES_EDE_CBC_SHA",
    "0090": "DHE_PSK_WITH_AES_128_CBC_SHA",
    "0091": "DHE_PSK_WITH_AES_256_CBC_SHA",
    "0092": "RSA_PSK_WITH_RC4_128_SHA",
    "0093": "RSA_PSK_WITH_3DES_EDE_CBC_SHA",
    "0094": "RSA_PSK_WITH_AES_128_CBC_SHA",
    "0095": "RSA_PSK_WITH_AES_256_CBC_SHA",
    "0096": "RSA_WITH_SEED_CBC_SHA",
    "0097": "DH_DSS_WITH_SEED_CBC_SHA",
    "0098": "DH_RSA_WITH_SEED_CBC_SHA",
    "0099": "DHE_DSS_WITH_SEED_CBC_SHA",
    "009a": "DHE_RSA_WITH_SEED_CBC_SHA",
    "009b": "DH_anon_WITH_SEED_CBC_SHA",
    "009c": "RSA_WITH_AES_128_GCM_SHA256",
    "009d": "RSA_WITH_AES_256_GCM_SHA384",
    "009e": "DHE_RSA_WITH_AES_128_GCM_SHA256",
    "009f": "DHE_RSA_WITH_AES_256_GCM_SHA384",
    "00a0": "DH_RSA_WITH_AES_128_GCM_SHA256",
    "00a1": "DH_RSA_WITH_AES_256_GCM_SHA384",
    "00a2": "DHE_DSS_WITH_AES_128_GCM_SHA256",
    "00a3": "DHE_DSS_WITH_AES_256_GCM_SHA384",
    "00a4": "DH_DSS_WITH_AES_128_GCM_SHA256",
    "00a5": "DH_DSS_WITH_AES_256_GCM_SHA384",
    "00a6": "DH_anon_WITH_AES_128_GCM_SHA256",
    "00a7": "DH_anon_WITH_AES_256_GCM_SHA384",
    "00a8": "PSK_WITH_AES_128_GCM_SHA256",
    "00a9": "PSK_WITH_AES_256_GCM_SHA384",
    "00aa": "DHE_PSK_WITH_AES_128_GCM_SHA256",
    "00ab": "DHE_PSK_WITH_AES_256_GCM_SHA384",
    "00ac": "RSA_PSK_WITH_AES_128_GCM_SHA256",
    "00ad": "RSA_PSK_WITH_AES_256_GCM_SHA384",
    "00ae": "PSK_WITH_AES_128_CBC_SHA256",
    "00af": "PSK_WITH_AES_256_CBC_SHA384",
    "00b0": "PSK_WITH_NULL_SHA256",
    "00b1": "PSK_WITH_NULL_SHA384",
    "00b2": "DHE_PSK_WITH_AES_128_CBC_SHA256",
    "00b3": "DHE_PSK_WITH_AES_256_CBC_SHA384",
    "00b4": "DHE_PSK_WITH_NULL_SHA256",
    "00b5": "DHE_PSK_WITH_NULL_SHA384",
    "00b6": "RSA_PSK_WITH_AES_128_CBC_SHA256",
    "00b7": "RSA_PSK_WITH_AES_256_CBC_SHA384",
    "00b8": "RSA_PSK_WITH_NULL_SHA256",
    "00b9": "RSA_PSK_WITH_NULL_SHA384",
    "00ba": "RSA_WITH_CAMELLIA_128_CBC_SHA256",
    "00bb": "DH_DSS_WITH_CAMELLIA_128_CBC_SHA256",
    "00bc": "DH_RSA_WITH_CAMELLIA_128_CBC_SHA256",
    "00bd": "DHE_DSS_WITH_CAMELLIA_128_CBC_SHA256",
    "00be": "DHE_RSA_WITH_CAMELLIA_128_CBC_SHA256",
    "00bf": "DH_anon_WITH_CAMELLIA_128_CBC_SHA256",
    "00c0": "RSA_WITH_CAMELLIA_256_CBC_SHA256",
    "00c1": "DH_DSS_WITH_CAMELLIA_256_CBC_SHA256",
    "00c2": "DH_RSA_WITH_CAMELLIA_256_CBC_SHA256",
    "00c3": "DHE_DSS_WITH_CAMELLIA_256_CBC_SHA256",
    "00c4": "DHE_RSA_WITH_CAMELLIA_256_CBC_SHA256",
    "00c5": "DH_anon_WITH_CAMELLIA_256_CBC_SHA256",
    "00ff": "EMPTY_RENEGOTIATION_INFO_SCSV",
    "5600": "FALLBACK_SCSV",
    "c001": "ECDH_ECDSA_WITH_NULL_SHA",
    "c002": "ECDH_ECDSA_WITH_RC4_128_SHA",
    "c003": "ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA",
    "c004": "ECDH_ECDSA_WITH_AES_128_CBC_SHA",
    "c005": "ECDH_ECDSA_WITH_AES_256_CBC_SHA",
    "c006": "ECDHE_ECDSA_WITH_NULL_SHA",
    "c007": "ECDHE_ECDSA_WITH_RC4_128_SHA",
    "c008": "ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA",
    "c009": "ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
    "c00a": "ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
    "c00b": "ECDH_RSA_WITH_NULL_SHA",
    "c00c": "ECDH_RSA_WITH_RC4_128_SHA",
    "c00d": "ECDH_RSA_WITH_3DES_EDE_CBC_SHA",
    "c00e": "ECDH_RSA_WITH_AES_128_CBC_SHA",
    "c00f": "ECDH_RSA_WITH_AES_256_CBC_SHA",
    "c010": "ECDHE_RSA_WITH_NULL_SHA",
    "c011": "ECDHE_RSA_WITH_RC4_128_SHA",
    "c012": "ECDHE_RSA_WITH_3DES_EDE_CBC_SHA",
    "c013": "ECDHE_RSA_WITH_AES_128_CBC_SHA",
    "c014": "ECDHE_RSA_WITH_AES_256_CBC_SHA",
    "c015": "ECDH_anon_WITH_NULL_SHA",
    "c016": "ECDH_anon_WITH_RC4_128_SHA",
    "c017": "ECDH_anon_WITH_3DES_EDE_CBC_SHA",
    "c018": "ECDH_anon_WITH_AES_128_CBC_SHA",
    "c019": "ECDH_anon_WITH_AES_256_CBC_SHA",
    "c01a": "SRP_SHA_WITH_3DES_EDE_CBC_SHA",
    "c01b": "SRP_SHA_RSA_WITH_3DES_EDE_CBC_SHA",
    "c01c": "SRP_SHA_DSS_WITH_3DES_EDE_CBC_SHA",
    "c01d": "SRP_SHA_WITH_AES_128_CBC_SHA",
    "c01e": "SRP_SHA_RSA_WITH_AES_128_CBC_SHA",
    "c01f": "SRP_SHA_DSS_WITH_AES_128_CBC_SHA",
    "c020": "SRP_SHA_WITH_AES_256_CBC_SHA",
    "c021": "SRP_SHA_RSA_WITH_AES_256_CBC_SHA",
    "c022": "SRP_SHA_DSS_WITH_AES_256_CBC_SHA",
    "c023": "ECDHE_ECDSA_WITH_AES_128_CBC_SHA256",
    "c024": "ECDHE_ECDSA_WITH_AES_256_CBC_SHA384",
    "c025": "ECDH_ECDSA_WITH_AES_128_CBC_SHA256",
    "c026": "ECDH_ECDSA_WITH_AES_256_CBC_SHA384",
    "c027": "ECDHE_RSA_WITH_AES_128_CBC_SHA256",
    "c028": "ECDHE_RSA_WITH_AES_256_CBC_SHA384",
    "c029": "ECDH_RSA_WITH_AES_128_CBC_SHA256",
    "c02a": "ECDH_RSA_WITH_AES_256_CBC_SHA384",
    "c02b": "ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "c02c": "ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "c02d": "ECDH_ECDSA_WITH_AES_128_GCM_SHA256",
    "c02e": "ECDH_ECDSA_WITH_AES_256_GCM_SHA384",
    "c02f": "ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "c030": "ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "c031": "ECDH_RSA_WITH_AES_128_GCM_SHA256",
    "c032": "ECDH_RSA_WITH_AES_256_GCM_SHA384",
    "c033": "ECDHE_PSK_WITH_RC4_128_SHA",
    "c034": "ECDHE_PSK_WITH_3DES_EDE_CBC_SHA",
    "c035": "ECDHE_PSK_WITH_AES_128_CBC_SHA",
    "c036": "ECDHE_PSK_WITH_AES_256_CBC_SHA",
    "c037": "ECDHE_PSK_WITH_AES_128_CBC_SHA256",
    "c038": "ECDHE_PSK_WITH_AES_256_CBC_SHA384",
    "c039": "ECDHE_PSK_WITH_NULL_SHA",
    "c03a": "ECDHE_PSK_WITH_NULL_SHA256",
    "c03b": "ECDHE_PSK_WITH_NULL_SHA384",
    "c03c": "RSA_WITH_ARIA_128_CBC_SHA256",
    "c03d": "RSA_WITH_ARIA_256_CBC_SHA384",
    "c03e": "DH_DSS_WITH_ARIA_128_CBC_SHA256",
    "c03f": "DH_DSS_WITH_ARIA_256_CBC_SHA384",
    "c040": "DH_RSA_WITH_ARIA_128_CBC_SHA256",
    "c041": "DH_RSA_WITH_ARIA_256_CBC_SHA384",
    "c042": "DHE_DSS_WITH_ARIA_128_CBC_SHA256",
    "c043": "DHE_DSS_WITH_ARIA_256_CBC_SHA384",
    "c044": "DHE_RSA_WITH_ARIA_128_CBC_SHA256",
    "c045": "DHE_RSA_WITH_ARIA_256_CBC_SHA384",
    "c046": "DH_anon_WITH_ARIA_128_CBC_SHA256",
    "c047": "DH_anon_WITH_ARIA_256_CBC_SHA384",
    "c048": "ECDHE_ECDSA_WITH_ARIA_128_CBC_SHA256",
    "c049": "ECDHE_ECDSA_WITH_ARIA_256_CBC_SHA384",
    "c04a": "ECDH_ECDSA_WITH_ARIA_128_CBC_SHA256",
    "c04b": "ECDH_ECDSA_WITH_ARIA_256_CBC_SHA384",
    "c04c": "ECDHE_RSA_WITH_ARIA_128_CBC_SHA256",
    "c04d": "ECDHE_RSA_WITH_ARIA_256_CBC_SHA384",
    "c04e": "ECDH_RSA_WITH_ARIA_128_CBC_SHA256",
    "c04f": "ECDH_RSA_WITH_ARIA_256_CBC_SHA384",
    "c050": "RSA_WITH_ARIA_128_GCM_SHA256",
    "c051": "RSA_WITH_ARIA_256_GCM_SHA384",
    "c052": "DHE_RSA_WITH_ARIA_128_GCM_SHA256",
    "c053": "DHE_RSA_WITH_ARIA_256_GCM_SHA384",
    "c054": "DH_RSA_WITH_ARIA_128_GCM_SHA256",
    "c055": "DH_RSA_WITH_ARIA_256_GCM_SHA384",
    "c056": "DHE_DSS_WITH_ARIA_128_GCM_SHA256",
    "c057": "DHE_DSS_WITH_ARIA_256_GCM_SHA384",
    "c058": "DH_DSS_WITH_ARIA_128_GCM_SHA256",
    "c059": "DH_DSS_WITH_ARIA_256_GCM_SHA384",
    "c05a": "DH_anon_WITH_ARIA_128_GCM_SHA256",
    "c05b": "DH_anon_WITH_ARIA_256_GCM_SHA384",
    "c05c": "ECDHE_ECDSA_WITH_ARIA_128_GCM_SHA256",
    "c05d": "ECDHE_ECDSA_WITH_ARIA_256_GCM_SHA384",
    "c05e": "ECDH_ECDSA_WITH_ARIA_128_GCM_SHA256",
    "c05f": "ECDH_ECDSA_WITH_ARIA_256_GCM_SHA384",
    "c060": "ECDHE_RSA_WITH_ARIA_128_GCM_SHA256",
    "c061": "ECDHE_RSA_WITH_ARIA_256_GCM_SHA384",
    "c062": "ECDH_RSA_WITH_ARIA_128_GCM_SHA256",
    "c063": "ECDH_RSA_WITH_ARIA_256_GCM_SHA384",
    "c064": "PSK_WITH_ARIA_128_CBC_SHA256",
    "c065": "PSK_WITH_ARIA_256_CBC_SHA384",
    "c066": "DHE_PSK_WITH_ARIA_128_CBC_SHA256",
    "c067": "DHE_PSK_WITH_ARIA_256_CBC_SHA384",
    "c068": "RSA_PSK_WITH_ARIA_128_CBC_SHA256",
    "c069": "RSA_PSK_WITH_ARIA_256_CBC_SHA384",
    "c06a": "PSK_WITH_ARIA_128_GCM_SHA256",
    "c06b": "PSK_WITH_ARIA_256_GCM_SHA384",
    "c06c": "DHE_PSK_WITH_ARIA_128_GCM_SHA256",
    "c06d": "DHE_PSK_WITH_ARIA_256_GCM_SHA384",
    "c06e": "RSA_PSK_WITH_ARIA_128_GCM_SHA256",
    "c06f": "RSA_PSK_WITH_ARIA_256_GCM_SHA384",
    "c070": "ECDHE_PSK_WITH_ARIA_128_CBC_SHA256",
    "c071": "ECDHE_PSK_WITH_ARIA_256_CBC_SHA384",
    "c072": "ECDHE_ECDSA_WITH_CAMELLIA_128_CBC_SHA256",
    "c073": "ECDHE_ECDSA_WITH_CAMELLIA_256_CBC_SHA384",
    "c074": "ECDH_ECDSA_WITH_CAMELLIA_128_CBC_SHA256",
    "c075": "ECDH_ECDSA_WITH_CAMELLIA_256_CBC_SHA384",
    "c076": "ECDHE_RSA_WITH_CAMELLIA_128_CBC_SHA256",
    "c077": "ECDHE_RSA_WITH_CAMELLIA_256_CBC_SHA384",
    "c078": "ECDH_RSA_WITH_CAMELLIA_128_CBC_SHA256",
    "c079": "ECDH_RSA_WITH_CAMELLIA_256_CBC_SHA384",
    "c07a": "RSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c07b": "RSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c07c": "DHE_RSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c07d": "DHE_RSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c07e": "DH_RSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c07f": "DH_RSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c080": "DHE_DSS_WITH_CAMELLIA_128_GCM_SHA256",
    "c081": "DHE_DSS_WITH_CAMELLIA_256_GCM_SHA384",
    "c082": "DH_DSS_WITH_CAMELLIA_128_GCM_SHA256",
    "c083": "DH_DSS_WITH_CAMELLIA_256_GCM_SHA384",
    "c084": "DH_anon_WITH_CAMELLIA_128_GCM_SHA256",
    "c085": "DH_anon_WITH_CAMELLIA_256_GCM_SHA384",
    "c086": "ECDHE_ECDSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c087": "ECDHE_ECDSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c088": "ECDH_ECDSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c089": "ECDH_ECDSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c08a": "ECDHE_RSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c08b": "ECDHE_RSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c08c": "ECDH_RSA_WITH_CAMELLIA_128_GCM_SHA256",
    "c08d": "ECDH_RSA_WITH_CAMELLIA_256_GCM_SHA384",
    "c08e": "PSK_WITH_CAMELLIA_128_GCM_SHA256",
    "c08f": "PSK_WITH_CAMELLIA_256_GCM_SHA384",
    "c090": "DHE_PSK_WITH_CAMELLIA_128_GCM_SHA256",
    "c091": "DHE_PSK_WITH_CAMELLIA_256_GCM_SHA384",
    "c092": "RSA_PSK_WITH_CAMELLIA_128_GCM_SHA256",
    "c093": "RSA_PSK_WITH_CAMELLIA_256_GCM_SHA384",
    "c094": "PSK_WITH_CAMELLIA_128_CBC_SHA256",
    "c095": "PSK_WITH_CAMELLIA_256_CBC_SHA384",
    "c096": "DHE_PSK_WITH_CAMELLIA_128_CBC_SHA256",
    "c097": "DHE_PSK_WITH_CAMELLIA_256_CBC_SHA384",
    "c098": "RSA_PSK_WITH_CAMELLIA_128_CBC_SHA256",
    "c099": "RSA_PSK_WITH_CAMELLIA_256_CBC_SHA384",
    "c09a": "ECDHE_PSK_WITH_CAMELLIA_128_CBC_SHA256",
    "c09b": "ECDHE_PSK_WITH_CAMELLIA_256_CBC_SHA384",
    "c09c": "RSA_WITH_AES_128_CCM",
    "c09d": "RSA_WITH_AES_256_CCM",
    "c09e": "DHE_RSA_WITH_AES_128_CCM",
    "c09f": "DHE_RSA_WITH_AES_256_CCM",
    "c0a0": "RSA_WITH_AES_128_CCM_8",
    "c0a1": "RSA_WITH_AES_256_CCM_8",
    "c0a2": "DHE_RSA_WITH_AES_128_CCM_8",
    "c0a3": "DHE_RSA_WITH_AES_256_CCM_8",
    "c0a4": "PSK_WITH_AES_128_CCM",
    "c0a5": "PSK_WITH_AES_256_CCM",
    "c0a6": "DHE_PSK_WITH_AES_128_CCM",
    "c0a7": "DHE_PSK_WITH_AES_256_CCM",
    "c0a8": "PSK_WITH_AES_128_CCM_8",
    "c0a9": "PSK_WITH_AES_256_CCM_8",
    "c0aa": "PSK_DHE_WITH_AES_128_CCM_8",
    "c0ab": "PSK_DHE_WITH_AES_256_CCM_8",
    "c0ac": "ECDHE_ECDSA_WITH_AES_128_CCM",
    "c0ad": "ECDHE_ECDSA_WITH_AES_256_CCM",
    "c0ae": "ECDHE_ECDSA_WITH_AES_128_CCM_8",
    "c0af": "ECDHE_ECDSA_WITH_AES_256_CCM_8",
  }

  def __init__(self, domain=None, mxResolver=None, txtResolver=None, pinning='never', maxage=None, dane=True, trusted=None, time=None):
    self.domain      = domain
    self.pinning     = pinning
    self.maxage      = maxage
    self.dane        = dane
    self.trusted     = trusted
    self.time        = time
    self.mxResolver  = dns.resolver.Resolver()
    self.txtResolver = dns.resolver.Resolver()

    if txtResolver:
      self.txtResolver.nameservers = txtResolver.split(",")
    if mxResolver:
      self.mxResolver.nameservers  = mxResolver.split(",")

  def now(self):
    return self.time if self.time != None else time.time()


  def map(self, txt_records, dane = False):
      # Ignore empty txt records (unreachable hosts)
      txt_records  = filter(None, txt_records)
      notBefore    = (self.now() - self.maxage) if self.maxage != None else None
      fingerprints = set()
      ciphers      = set()
      options      = []
      errors       = False
      outdated     = False
      max_version  = None
      policy       = None

      # Always return default policy if none are reachable
      if len(txt_records) == 0:
          return self.DEFAULT_POLICY

      for txt in txt_records:
        # Convert key value pairs into a dictionary
        data = dict(s.split('=',2) for s in txt.split(" "))

        if data["starttls"] != "true":
            return self.DEFAULT_POLICY

        # Entry outdated?
        if notBefore and int(data['updated']) < notBefore:
            outdated = True

        # Collect fingerprints
        if "fingerprint" in data:
            for fp in data["fingerprint"].split(","):
                fingerprints.add(fp)

        # Collect ciphers
        if "tls-ciphers" in data:
            for cipher in data["tls-ciphers"].split(","):
                ciphers.add(self.CIPHERS[cipher])

        # Set maximum TLS version
        if "tls-versions" in data:
            version = max([int(v,16) for v in data["tls-versions"].split(",")])
            if max_version == None or version < max_version:
                max_version = version

        if "certificate-problems" in data or (self.trusted != None and ("trusted" not in data or self.trusted not in data["trusted"].split(","))):
            errors = True

      # Don't rely on anything
      if outdated:
        return "encrypt"

      # exclude insecure and unused ciphers
      if len(ciphers) > 0:
        text    = ",".join(ciphers)
        exclude = ["aNULL","eNULL"]
        for str in ["RC4","EXP","SEED","DES","3DES","CAMELLIA"]:
            if not "_"+str in text:
                exclude.append(str)
        options.extend(" exclude=" + ":".join(exclude))

      # Set allowed TLS protocol versions
      if max_version != None and max_version in self.TLS_VERSIONS:
          options.append(" protocols=" + self.TLS_VERSIONS[max_version])

      if dane:
          policy = "dane-only"
      elif (self.pinning=='always' or (errors and self.pinning=='on-errors')) and len(fingerprints) > 0:
          # Enable certificate pining
          options.extend("".join([" match=" + ":".join(re.findall("..",fp)) for fp in fingerprints]))
          policy = "fingerprint"
      elif errors:
          policy = "encrypt"
      else:
          policy = "verify"

      return policy + "".join(options)


  def resolve_and_map(self, nexthop):
      try:
          # Query MX records
          mx_records  = self.mxResolver.query(nexthop,'MX')
          dane        = False
          txt_records = []

          # Query TXT records for the MX records
          for mx in mx_records:
              if self.dane:
                  try:
                      # Check for TLSA mx_records
                      self.mxResolver.query('_25._tcp.' + str(mx.exchange), 'TLSA')
                      dane = True
                  except dns.resolver.NXDOMAIN:
                      None

              query   = "%s%s" % (mx.exchange, self.domain)
              answers = self.txtResolver.query(query,'TXT')
              txt_records.append("".join(answers[0].strings))

          # Map TXT records to TLS policy
          return self.map(txt_records, dane=dane)

      # In case of other results than "OK" postfix does a second
      # lookup for the parent domain.
      # i.e. example.com leads to a seconds lookup for .com
      # This can be avoided by returning "OK"
      except dns.exception.Timeout:
          return self.DEFAULT_POLICY
      except dns.resolver.NoNameservers:
          return self.DEFAULT_POLICY
      except dns.resolver.NXDOMAIN:
          return self.DEFAULT_POLICY
      except dns.resolver.NoAnswer:
          return self.DEFAULT_POLICY


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='TLS Policy Map daemon using the socketmap protocol')
    parser.add_argument('--socket',       help='Path to unix socket', default="/var/run/tlspolicy.sock")
    parser.add_argument('--domain',       help='Domain for lookups',  default="")
    parser.add_argument('--fingerprints', help='Use certificate pinning with fingerprints', default='always', choices=['always', 'on-problems', 'never'])
    parser.add_argument('--mxresolver',   help='Nameserver for MX and TLSA lookups',  default="")
    parser.add_argument('--txtresolver',  help='Nameserver for TXT lookups', default="")
    parser.add_argument('--trusted',      help='Name of trusted root store', default="system")
    parser.add_argument('--maxage',       help='Maximum age of TXT records in seconds', type=int)
    parser.add_argument('--dane',         help='Use DANE if TLSA records exists', default='true', choices=['true','false'])
    args = parser.parse_args()

    # Set options
    TlsPolicyHandler.tlsPolicy = TlsPolicyMap(
      domain      = args.domain,
      pinning     = args.fingerprints,
      mxResolver  = args.mxresolver,
      txtResolver = args.txtresolver,
      trusted     = args.trusted,
      maxage      = args.maxage,
      dane        = args.dane=="true",
    )

    # Start server
    Daemon(args.socket,TlsPolicyHandler).run()

