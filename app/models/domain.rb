require 'icann'

class Domain < ActiveRecord::Base

  RESOLVER = '8.8.8.8'

  after_create :enqueue_resolve

  scope :with_mx,       ->{ where 'ARRAY_LENGTH(mx_hosts,1) > 0' }
  scope :without_mx,    ->{ where 'ARRAY_LENGTH(mx_hosts,1) IS NULL' }
  scope :with_error,    ->{ where 'error IS NOT NULL' }
  scope :without_error, ->{ where 'error IS NULL' }

  def enqueue_resolve
    ResolverJob.perform_later(self, 'create_mx_hosts')
  end

  # SELECT COUNT(*), unnest(mx_hosts) FROM domains GROUP BY unnest(mx_hosts) ORDER BY COUNT(*) DESC;

  def valid_mx?
    mx_hosts.any?{|name| ICANN.fqdn?(name) }
  end

  def invalid_mx?
    mx_hosts.any?{|name| !ICANN.fqdn?(name) }
  end

  def self.mx_hosts
    connection.select_values "SELECT unnest(mx_hosts) from domains GROUP BY unnest(mx_hosts)"
  end

  def mx_validity
    valid   = valid_mx?
    invalid = invalid_mx?
    if valid && invalid
      :mixed
    elsif valid
      :valid
    elsif invalid
      :invalid
    else
      nil
    end
  end

end
