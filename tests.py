#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-unittest2
#
# Run with:
# unit2 discover
#

import unittest2
from tlspolicy import *

class TestMap(unittest2.TestCase):

    def map(self,txt):
        return TlsPolicyMap().map(txt)

    def test_starttls_true(self):
        self.assertEqual(self.map(["starttls=true"]), 'verify')
        self.assertEqual(self.map(["starttls=true",""]), 'verify')
        self.assertEqual(self.map(["starttls=true","starttls=false"]), 'may')

    def test_starttls_false(self):
        self.assertEqual(self.map([""]), 'may')
        self.assertEqual(self.map(["starttls=false"]), 'may')
        self.assertEqual(self.map(["starttls=false",""]), 'may')

    def test_timestamp(self):
        policyMap = TlsPolicyMap(maxage=123)

        # not yet outdated
        self.assertEqual(policyMap.map(["starttls=true updated=123 trusted=system"]), 'verify')

        # outdated
        self.assertEqual(policyMap.map(["starttls=true updated=122"]), 'encrypt')

        # only one outdated
        self.assertEqual(policyMap.map(["starttls=true updated=130","starttls=true updated=120"]), 'encrypt')

    def test_pinning_on_errors(self):
        policyMap = TlsPolicyMap(pinning='on-errors')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=abcd"]), 'verify')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=abcd certificate-problems=expired"]), 'fingerprint match=abcd')

    def test_pinning_always(self):
        policyMap = TlsPolicyMap(pinning='always')
        self.assertEqual(policyMap.map(["starttls=true"]), 'verify')
        self.assertEqual(policyMap.map(["starttls=true certificate-problems=expired"]), 'encrypt')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=abcd"]), 'fingerprint match=abcd')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=dead,beef"]), 'fingerprint match=dead match=beef')
        self.assertEqual(policyMap.map(["starttls=true fingerprint=dead,beef","starttls=true fingerprint=feed"]),
            'fingerprint match=dead match=beef match=feed')

    def test_certificate_valid(self):
        self.assertEqual(self.map(["starttls=true"]), 'verify')

    def test_certificate_problems(self):
        self.assertEqual(self.map(["starttls=true certificate-problems=mismatch"]), 'encrypt')
        self.assertEqual(self.map(["starttls=true certificate-problems=mismatch fingerprint=abcd"]), 'encrypt')

    # TODO Add DANE support


class TestResolve(unittest2.TestCase):

    def resolve_and_map(self,txt):
        policyMap = TlsPolicyMap(domain="tls-scan.informatik.uni-bremen.de", txtResolver="134.102.201.91")
        return policyMap.resolve_and_map(txt)

    def test_dane_with_existing_dane(self):
        self.assertEqual(self.resolve_and_map("mx1.mailbox.org"), 'dane-only')

    def test_resolve_mx_with_records(self):
        self.assertEqual(self.resolve_and_map("tigre.interieur.gouv.fr"), 'encrypt')

    def test_without_mx_and_with_a(self):
        self.assertEqual(self.resolve_and_map("example.com"), 'may')

    def test_without_mx_and_without_a(self):
        self.assertEqual(self.resolve_and_map("foo.example.com"), 'may')
