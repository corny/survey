module Vars

  MX_WITH_TLSA = 201
  SHA1_OIDS = %w(
    1.2.840.113549.1.1.5
    1.3.14.3.2.29
  )

  METHODS = %w(
    domains
    hosts
    roots
    certificates
    mx_records
    mx_domains
  )

  extend self

  def domains
    total     = Domain.count
    reachable = DomainsMx.where("mx_hostname IN (SELECT hostname FROM mx_addresses INNER JOIN mx_hosts ON mx_hosts.address=mx_addresses.address AND mx_hosts.starttls IS NOT NULL)").count("DISTINCT(name)")
    h = {
      total:      total,
      with_mx:    count_ratio(Domain.with_mx.count, total),
      without_mx: count_ratio(Domain.without_error.without_mx.count, total),
      servfail:   count_ratio(Domain.with_error.count, total),
      mx_stats:   Stats.domains,
      reachable:  {
        total:            reachable,
        starttls:         count_ratio(DomainsMx.where("mx_hostname IN (SELECT hostname FROM mx_records WHERE starttls)").count("DISTINCT(name)"), reachable),
        without_problems: count_ratio(DomainsMx.where("mx_hostname IN (SELECT hostname FROM mx_records WHERE starttls AND cert_problems IS null)").count("DISTINCT(name)"), reachable),
      }
    }
    h
  end

  def mx_records
    total = MxRecord.count
    starttls_hosts = MxHost.with_mx_record
    {
      unique_hostnames:    total,
      unique_addresses:    MxAddress.count("DISTINCT(address)"),
      with_addresses:      MxRecord.with_address.count,
      nonpublic_addresses: Stats.mx_address_scopes.reject{|k,_| k.starts_with?("GLOBAL UNICAST") }.values.sum,
      with_starttls:       count_ratio(MxRecord.where(starttls: true).count, total),
      all_valid:           count_ratio(MxRecord.without_problems.trusted.count, total),
      with_tlsa:           count_ratio(MX_WITH_TLSA, total),
      starttls_hosts:      count_ratio(starttls_hosts.without_error.count, starttls_hosts.count),
    }
  end

  def mx_domains
    domains = Domain.mx_hosts
    total   = domains.count
    invalid = domains.reject{|domain| ICANN.fqdn?(domain) }
    {
      invalid: count_ratio(invalid.count, total)
    }
  end

  def hosts
    scope = MxHost.ipv4
    total = scope.count
    h = {
      total:               total,
      ssl_only:            scope.where(tls_versions: "{\\\\x0300}").count,
      mozilla_root_without_trustbit: scope.where(chain_root_id: RootCertificates.instance.entries.reject(&:trustbit_websites).map(&:id) ).count,
      # Anzahl eindeutiger Zertifikate von Hosts mit Zertifikaten
    }

    # Anteile von Hosts mit STARTTLS, TLS, Certificates
    %w( with_starttls with_tls with_certificates without_error ).each do |method|
      h[method] = count_ratio(scope.send(method).count, total)
    end

    # Anteil einmal/mehrfach verwendeter Server-Zertifikate
    h.merge!(
      unique_certificates:      scope.with_certificates.count("DISTINCT(certificate_id)"),
      with_unique_certificates: count_ratio(scope.with_once_used_certificate.count, h['with_certificates'][:count]),
      with_shared_certificates: count_ratio(scope.with_multiple_used_certificate.count, h['with_certificates'][:count]),
    )

    # Verhältnis von IP-Adressen zu Server-Zertifikaten
    h[:per_certificate] = h['with_certificates'][:count].to_f / h[:unique_certificates]

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
    total     = Certificate.count
    rsa       = Certificate.where(key_algorithm: 'RSA')
    rsa_count = rsa.count
    sha1      = Certificate.where(signature_algorithm: SHA1_OIDS)
    {
      total: total,
      leaf:   count_ratio(Certificate.leaf.count, total),
      issuer: count_ratio(Certificate.issuer.count, total),
      keys: {
        unique:       Certificate.count("DISTINCT(key_id)"),
        duplicate:    count_ratio(Certificate.where("key_id IN (SELECT key_id FROM certificates GROUP BY key_id HAVING count(*) > 1 )").count, total),
      },
      rsa_keys: {
        two_thousand: count_ratio(rsa.where("key_size <= 1024").count, rsa_count),
        one_thousand: count_ratio(rsa.where("key_size >= 2048").count, rsa_count),
      },
      validity: {
        below_zero:     count_ratio(Certificate.where("days_valid <  0").count, total),
        below_one_year: count_ratio(Certificate.where("days_valid >= 0 AND days_valid <= 365").count, total),
      },
      sha_one_sunrised: count_ratio(sha1.where("not_after >= '2017-01-01'").count, sha1.count),
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
