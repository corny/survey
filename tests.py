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
        self.assertEqual(self.map("starttls=true"), 'encrypt')

    def test_starttls_false(self):
        self.assertEqual(self.map("starttls=false"), 'may')

    def test_certificate_trusted_match_mx(self):
        self.assertEqual(self.map("certificate=trusted,match-mx"), 'verify')

    def test_certificate_untrusted_match_mx(self):
        self.assertEqual(self.map("certificate=trusted,match-domain"), 'secure')

    # TODO Add DANE support
