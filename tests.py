#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-unittest2
#

import unittest2
from tlspolicy import *

class TestStringMethods(unittest2.TestCase):

    def map(self,txt):
        return TlsPolicyMap().map(txt)

    def test_starttls_true(self):
        self.assertEqual(self.map(["starttls=true"]), 'encrypt')
        self.assertEqual(self.map(["starttls=true",""]), 'encrypt')
        self.assertEqual(self.map(["starttls=true","starttls=false"]), 'may')

    def test_starttls_false(self):
        self.assertEqual(self.map([""]), 'may')
        self.assertEqual(self.map(["starttls=false"]), 'may')
        self.assertEqual(self.map(["starttls=false",""]), 'may')

    def test_fingerprint(self):
        policyMap = TlsPolicyMap(certPinning=True)
        self.assertEqual(policyMap.map(["starttls=true"]), 'encrypt')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=abcd"]), 'fingerprint match=abcd')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=dead,beef"]), 'fingerprint match=dead match=beef')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=dead,beef","starttls=true fingerprint=feed"]),
            'fingerprint match=dead match=beef match=feed')

    def test_certificate_trusted_match_mx(self):
        self.assertEqual(self.map(["starttls=true certificate=trusted,match-mx"]), 'verify')

    def test_certificate_untrusted_match_mx(self):
        self.assertEqual(self.map(["starttls=true certificate=trusted,match-domain"]), 'secure')

    # TODO Add DANE support


class TestMx(unittest2.TestCase):

    def resolve_and_map(self,txt):
        policyMap = TlsPolicyMap(domain="tls-scan.informatik.uni-bremen.de", txtResolver="134.102.201.91")
        return policyMap.resolve_and_map(txt)

    def test_resolve_mx_with_records(self):
        self.assertEqual(self.resolve_and_map("tigre.interieur.gouv.fr"), 'encrypt')

    def test_without_mx_and_with_a(self):
        self.assertEqual(self.resolve_and_map("example.com"), 'may')

    def test_without_mx_and_without_a(self):
        self.assertEqual(self.resolve_and_map("foo.example.com"), 'may')
