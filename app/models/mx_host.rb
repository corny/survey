class MxHost < ActiveRecord::Base

  def self.create_by_hostname(hostname)
    hostname = hostname.downcase

    # already exists?
    return true if where(hostname: hostname).any?

    addresses = Resolv::DNS.open do |dns|
      dns.getaddresses(hostname)
    end
    
    begin
      transaction do
        addresses.each do |record|
          find_or_initialize_by(hostname: hostname, address: record.to_s)
        end
      end
    rescue PG::UniqueViolation
      # hopefully a race condition
      retry
    end
  end

end
