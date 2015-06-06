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
    total = MxHost.count
    h = {
      total: total,
      mozilla_root_without_trustbit: MxHost.where(chain_root_id: RootCertificates.instance.entries.reject(&:trustbit_websites).map(&:id) ).count,
    }

    # Anteile von Hosts mit STARTTLS, TLS, Certificates
    %w( with_starttls with_tls with_certificates without_error ).each do |scope|
      count = MxHost.send(scope).count
      h[scope] = {
        count: count,
        ratio: count.to_f / total
      }
    end
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
      keys: {
        smallRSA: Certificate.where("key_algorithm='RSA' AND key_size < 2000").count,
      },
      validity: {
        below_zero: Certificate.where("days_valid < 0").count,
      }
    }
  end

end
