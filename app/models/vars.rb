module Vars

  extend self

  def to_h
    {
      domains:      domains,
      hosts:        hosts,
      certificates: certificates,
      mx_records:   mx_records,
    }
  end

  def domains
    {
      total:    Domain.count,
      mx_stats: Stats.domains,
    }
  end

  def mx_records
    {
      with_addresses:   MxRecord.with_address.count,
      unique_addresses: MxRecord.with_address.count("DISTINCT(address)"),
      unique_hostnames: MxRecord.count("DISTINCT(hostname)"),
    }
  end

  def hosts
    total     = MxHost.count
    tls_count = MxHost.with_tls.count
    h = {
      total: total,
      tls: {
        count: tls_count,
        ratio: tls_count.to_f / total,
      }
    }


    h[:starttls_percent] = h[:starttls].to_f / h[:total] * 100
    h
  end

  def certificates
    {
      total: Certificate.count,
      validity: {
        below_zero: Certificate.where("days_valid < 0").count
      }
    }
  end

end
