#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-dnspython
#

import socket
import sys
import os
import dns.resolver
import argparse

class TlsPolicy:


    def __init__(self, domain, nameserver):
        self.domain   = domain
        self.resolver = dns.resolver.Resolver()
        self.resolver.nameservers = [nameserver]

    def check(self, txt):
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

    def run(self, sockpath):
        # Make sure the socket does not already exist
        try:
            os.unlink(sockpath)
        except OSError:
            if os.path.exists(sockpath):
                raise

        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        # Bind the socket to the port
        print >>sys.stderr, 'starting up on %s' % sockpath
        sock.bind(sockpath)

        # Listen for incoming connections
        sock.listen(1)

        while True:
            # Wait for a connection
            print >>sys.stderr, 'waiting for connections'
            connection, client_address = sock.accept()
            try:
                print >>sys.stderr, 'connection from', client_address

                # Receive the data in small chunks and retransmit it
                data = connection.recv(255)
                if not " " in data:
                    print("break 1")
                    break;
                name, remaining = data.split(" ")
                if not "," in remaining:
                    print("break 2")
                    break;
                nexthop, _  = remaining.split(",")

                if data:
                    answers = self.resolver.query("%s.%s" % (nexthop, self.domain),'TXT')

                    if len(answers) > 0:
                        connection.sendall("OK %s" % self.check(answers[0].strings[0]))
            except dns.exception.Timeout:
                connection.sendall("TIMEOUT ")
            except dns.resolver.NoNameservers:
                connection.sendall("NOTFOUND ")
            finally:
                print("close")
                # Clean up the connection
                connection.close()

if __name__ == "__main__":


    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--socket',     help='path to unix socket', default="/tmp/tls_policy.sock")
    parser.add_argument('--domain',     help='domain for lookups',  default="tls-scan.informatik.uni-bremen.de")
    parser.add_argument('--nameserver', help='nameserver to query', default="134.102.201.92")

    args = parser.parse_args()

    TlsPolicy(args.domain, args.nameserver).run(args.socket)
