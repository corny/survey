module Stats

  extend self

  def domains
    result = Hash[Domain.select("error, COUNT(*) AS count").with_error.group(:error).map{|r| [r.error, r.count] }]
    result.merge! \
      with_mx:    domains_mx_stats,
      without_mx: Domain.without_mx.without_error.count
  end

  def mx_stats
    result = {}
    Domain.mx_hosts.each do |host|
      validity = ICANN.fqdn_validity(host)
      result[validity] ||= 0
      result[validity]  += 1
    end
    result
  end

  def domains_mx_stats
    result = {}
    Domain.with_mx.find_each batch_size: 10000 do |d|
      validity = d.mx_validity
      result[validity] ||= 0
      result[validity]  += 1
    end
    result
  end

  def tls_versions
    MxHost.where("tls_version IS NOT NULL").select("tls_version, COUNT(*) AS count").group(:tls_version).order(:tls_version)
  end

  def hostnames_per_address(limit=50)
    MxHost.select("address, COUNT(*) AS count").group(:address).order("count DESC").limit(limit)
  end

  def issuers(limit=50)
    Certificate.select("min(id) AS id, issuer_id, count(*) AS count").group(:issuer_id).order("count DESC").limit(limit)
  end

end