#!/usr/bin/env python2
#
# Requirements:
# apt-get install python-unittest2
#

import unittest2
from tlspolicy import *

class TestStringMethods(unittest2.TestCase):

    def check(self,txt):
        return TlsPolicy(None,None).check(txt)

    def test_starttls_true(self):
        self.assertEqual(self.check("starttls=true"), 'encrypt')

    def test_starttls_false(self):
        self.assertEqual(self.check("starttls=false"), 'may')

    def test_certificate_trusted_match_mx(self):
        self.assertEqual(self.check("certificates=trusted,match-mx"), 'verify')

    def test_certificate_untrusted_match_mx(self):
        self.assertEqual(self.check("certificates=trusted,match-domain"), 'secure')

    # TODO DANE
