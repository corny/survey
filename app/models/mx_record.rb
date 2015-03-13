class MxRecord < ActiveRecord::Base

  has_one :mx_host,
    foreign_key: :address,
    primary_key: :address

  scope :with_address,    ->{ where "address IS NOT null" }
  scope :without_address, ->{ where "address IS null" }
  scope :with_error,      ->{ where "dnserr IS NOT null" }
  scope :without_error,   ->{ where "dnserr IS null" }

  scope :cert_valid,      ->(bool){ where("EXISTS (SELECT * FROM mx_hosts WHERE address=mx_records.address AND cert_valid=" << (bool ? 'TRUE' : 'FALSE') << ")") }

  def self.valid_address?(address)
    addr = address.to_s
    addr != "0.0.0.0" && addr !~ /^(::|f[de])/
  end

end
