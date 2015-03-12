require 'rails_helper'
require 'icann'

describe ICANN do

  it{ expect(ICANN.fqdn_validity("")).to eq :invalid_domain_tld }
  it{ expect(ICANN.fqdn_validity("x")).to eq :invalid_tld }
  it{ expect(ICANN.fqdn_validity("1234.com")).to eq :valid }
  it{ expect(ICANN.fqdn_validity("example.com")).to eq :valid }
  it{ expect(ICANN.fqdn_validity("su-b.example.com")).to eq :valid }
  it{ expect(ICANN.fqdn_validity("com")).to eq :valid }
  it{ expect(ICANN.fqdn_validity("-x.com")).to eq :invalid_domain }
  it{ expect(ICANN.fqdn_validity("1.2.3.4")).to eq :invalid_tld }
  it{ expect(ICANN.fqdn_validity("example.xx")).to eq :invalid_tld }

end
