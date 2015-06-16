module Vars

  MX_WITH_TLSA = 201

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
    total = Domain.count
    {
      total:      total,
      with_mx:    count_ratio(Domain.with_mx.count, total),
      without_mx: count_ratio(Domain.without_error.without_mx.count, total),
      servfail:   count_ratio(Domain.with_error.count, total),
      mx_stats:   Stats.domains,
    }
  end

  def mx_records
    total = MxRecord.count
    {
      unique_hostnames:    total,
      unique_addresses:    MxAddress.count("DISTINCT(address)"),
      with_addresses:      MxRecord.with_address.count,
      nonpublic_addresses: Stats.mx_address_scopes.reject{|k,_| k.starts_with?("GLOBAL UNICAST") }.values.sum,
      with_starttls:       count_ratio(MxRecord.where(starttls: true).count, total),
      all_valid:           count_ratio(MxRecord.without_problems.trusted.count, total),
      with_tlsa:           count_ratio(MX_WITH_TLSA, total),
    }
  end

  def hosts
    total = MxHost.count
    h = {
      total: total,
      ssl_only: MxHost.where(tls_versions: "{\\\\x0300}").count,
      mozilla_root_without_trustbit: MxHost.where(chain_root_id: RootCertificates.instance.entries.reject(&:trustbit_websites).map(&:id) ).count,
    }

    # Anteile von Hosts mit STARTTLS, TLS, Certificates
    %w( with_starttls with_tls with_certificates without_error ).each do |scope|
      count = MxHost.send(scope).count
      h[scope] = count_ratio(count, total)
    end
    h
  end

  def roots
    entries = RootCertificates.instance.entries
    total   = entries.count
    {
      total:            total,
      used:             count_ratio(entries.select(&:used?).count, total),
      without_trustbit: count_ratio(entries.reject(&:trustbit_websites).count, total),
    }
  end

  def certificates
    total = Certificate.count
    {
      total: total,
      keys: {
        bsiTwothousand:   count_ratio(Certificate.where("key_algorithm='RSA' AND key_size < 2000").count, total),
        bsiThreethousand: count_ratio(Certificate.where("key_algorithm='RSA' AND key_size < 3000").count, total),
      },
      validity: {
        below_zero:     count_ratio(Certificate.where("days_valid < 0").count, total),
        below_one_year: count_ratio(Certificate.where("days_valid > 0 AND days_valid <= 365").count, total),
      }
    }
  end

  protected

  def count_ratio(count,total)
    {
      count: count,
      ratio: count.to_f / total
    }
  end

end
