#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-dnspython
#
import SocketServer

import sys
import os
import dns.resolver
import argparse
import signal


class TlsPolicy:

    domain   = None
    resolver = dns.resolver.Resolver()

    def map(self, txt):
        data = dict(s.split('=') for s in txt.split(" "))

        if "certificates" in data:
            certificates = data["certificates"].split(",")
            if "trusted" in certificates:
                if "match-domain" in certificates:
                    return "secure"
                if "match-mx" in certificates:
                    return "verify"

        if data["starttls"]=="true":
            return "encrypt"
        else:
            return "may"

    def resolve_and_map(self, input):

        try:
            # Receive the data in small chunks and retransmit it
            if not " " in input:
                return "PERM invalid request (1)\n"

            name, remaining = input.split(" ")
            if not "," in remaining:
                return "PERM invalid request (2)\n"

            nexthop = remaining.split(",")[0]
            query   = "%s.%s" % (nexthop, self.domain)
            print("query for %s" % query)

            answers = self.resolver.query(query,'TXT')

            if len(answers) > 0:
                return "OK %s\n" % self.map(answers[0].strings[0])

        except dns.exception.Timeout:
            return "TIMEOUT \n"
        except dns.resolver.NoAnswer:
            return "NOTFOUND \n"
        except dns.resolver.NoNameservers:
            return "TEMP \n"


class TlsPolicyHandler(SocketServer.BaseRequestHandler):
    def handle(self):
        self.request.sendall(TlsPolicy().resolve_and_map(self.request.recv(255)))


class ThreadedServer(SocketServer.ThreadingMixIn, SocketServer.UnixStreamServer):
    pass


if __name__ == "__main__":
    import socket
    import threading

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--socket',     help='path to unix socket', default="/tmp/tls_policy.sock")
    parser.add_argument('--domain',     help='domain for lookups',  default="tls-scan.informatik.uni-bremen.de")
    parser.add_argument('--nameserver', help='nameserver to query', default="134.102.201.91")

    args = parser.parse_args()

    # Set options
    TlsPolicy.resolver.nameservers = [args.nameserver]
    TlsPolicy.domain               = args.domain

    def shutdown(signal,frame):
        print "shutting down"
        os.remove(args.socket)
        server.shutdown()

    # Set signal handlers
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    # Start server
    server = ThreadedServer(args.socket, TlsPolicyHandler)
    thread = threading.Thread(target=server.serve_forever)
    thread.daemon = True
    thread.start()

    print "waiting for connections"
    signal.pause()
