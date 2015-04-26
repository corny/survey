#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-unittest2
#

import unittest2
from tlspolicy import *

class TestStringMethods(unittest2.TestCase):

    def map(self,txt):
        return TlsPolicy.map(txt)

    def test_starttls_true(self):
        self.assertEqual(self.map(["starttls=true"]), 'encrypt')

    def test_starttls_false(self):
        self.assertEqual(self.map(["starttls=false"]), 'may')

    def test_certificate_trusted_match_mx(self):
        self.assertEqual(self.map(["certificate=trusted,match-mx"]), 'verify')

    def test_certificate_untrusted_match_mx(self):
        self.assertEqual(self.map(["certificate=trusted,match-domain"]), 'secure')

    # TODO Add DANE support


class TestMx(unittest2.TestCase):
    def setUp(self):
        TlsPolicy.domain = "tls-scan.informatik.uni-bremen.de"
        TlsPolicy.txtResolver.nameservers = ["134.102.201.91"]

    def test_resolve_mx_with_records(self):
        self.assertEqual(TlsPolicy.resolve_and_map("tigre.interieur.gouv.fr"), 'encrypt')

    def test_without_mx_and_with_a(self):
        self.assertEqual(TlsPolicy.resolve_and_map("example.com"), 'may')

    def test_without_mx_and_without_a(self):
        self.assertEqual(TlsPolicy.resolve_and_map("foo.example.com"), 'may')
