class Domain < ActiveRecord::Base

  after_create :enqueue_resolve

  # create mx_hosts by hostname
  def create_mx_hosts
    mx_hosts = []
    Resolv::DNS.open do |dns|
      transaction do
        dns.getresources(name, Resolv::DNS::Resource::IN::MX).each do |record|
          hostname = record.exchange.to_s.downcase
          MxHost.create_by_hostname(hostname)
          mx_hosts << hostname
        end
      end
    end
    self.update_attributes! mx_hosts: mx_hosts
  end

  def enqueue_resolve
    ResolverJob.perform_later(self, 'create_mx_hosts')
  end

end
