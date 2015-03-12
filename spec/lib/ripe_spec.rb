require 'rails_helper'
require 'ripe'

describe RIPE do

  it{ expect(RIPE.reserved_address?("192.167.0.1")).to eq false }
  it{ expect(RIPE.reserved_address?("192.168.0.1")).to eq true }
  it{ expect(RIPE.reserved_address?("::1")).to eq true }
  it{ expect(RIPE.reserved_address?("2a00:1450:4001:80e::")).to eq false }

  it{ expect(RIPE.reserved_network("192.167.0.1")).to eq nil }
  it{ expect(RIPE.reserved_network("192.168.0.1").to_s).to eq "192.168.0.0" }

end
