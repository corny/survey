require 'resolv'

class MxRecord < ActiveRecord::Base

  has_one :mx_host,
    foreign_key: :address,
    primary_key: :address

  scope :with_address,    ->{ where "address IS NOT null" }
  scope :without_address, ->{ where "address IS null" }
  scope :with_error,      ->{ where "dnserr IS NOT null" }
  scope :without_error,   ->{ where "dnserr IS null" }

  scope :cert_valid,      ->(bool){ where("EXISTS (SELECT * FROM mx_hosts WHERE address=mx_records.address AND cert_valid=" << (bool ? 'TRUE' : 'FALSE') << ")") }

  delegate *%i(
    starttls
    cert_valid
  ), to: :mx_host

  def self.valid_address?(address)
    addr = address.to_s
    addr != "0.0.0.0" && addr !~ /^(::|f[de])/
  end

  def valid_for_name?(name)
    mx_host.try(:certificate).try(:valid_for_name?, name)
  end

  def cert_invalid_or_mismatches?
    cert_matches==false || cert_valid==false
  end

  def reverse_name
    Resolv.getname address.to_s
  rescue Resolv::ResolvError
    raise unless $!.message.include?("no name")
  end

end
