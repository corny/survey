class MxHost < ActiveRecord::Base

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

end
