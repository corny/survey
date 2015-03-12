class MxRecord < ActiveRecord::Base

  scope :with_address,    ->{ where "address IS NOT null" }
  scope :without_address, ->{ where "address IS null" }
  scope :with_error,      ->{ where "dnserr IS NOT null" }
  scope :without_error,   ->{ where "dnserr IS null" }

  def self.valid_address?(address)
    addr = address.to_s
    addr != "0.0.0.0" && addr !~ /^(::|f[de])/
  end

end
