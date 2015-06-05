module Vars

  extend self

  def to_h
    {
      domains:      domains,
      hosts:        hosts,
      roots:        roots,
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
      mozilla_root_without_trustbit: MxHost.where(chain_root_id: RootCertificates.instance.entries.reject(&:trustbit_websites).map(&:id) ).count,
      tls: {
        count: tls_count,
        ratio: tls_count.to_f / total,
      }
    }


    h[:starttls_percent] = h[:starttls].to_f / h[:total] * 100
    h
  end

  def roots
    instance = RootCertificates.instance
    {
      total:            instance.entries.count,
      used:             instance.entries.select(&:used?).count,
      without_trustbit: instance.entries.reject(&:trustbit_websites).count,
    }
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
