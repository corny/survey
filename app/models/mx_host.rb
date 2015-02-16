class MxHost < ActiveRecord::Base

  belongs_to :certificate, foreign_key: :certificate_id, class_name: 'RawCertificate'

  Known = Set.new

  def self.known
    @known ||= Set.new MxHost.all.map(&:hostname)
  end

  def self.create_by_hostname(hostname)
    hostname = hostname.downcase

    # skip if already exists
    return if known.include?(hostname)
    known << hostname

    addresses = Resolv::DNS.open do |dns|
      dns.getaddresses(hostname)
    end
    
    begin
      transaction do
        addresses.each do |record|
          find_or_create_by(hostname: hostname, address: record.to_s)
        end
      end
    end
  end

  def self.valid_address?(address)
    addr = address.to_s
    addr != "0.0.0.0" && addr !~ /^(::|f[de])/
  end

end
