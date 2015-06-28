module Stats

  extend self

  SECOND_LEVEL_DOMAINS = Set.new %w(
    com.br
    com.au
    com.ua
    co.uk
    co.jp
    co.za
    co.kr
    ne.jp
  )

  MANGLE = YAML.load_file Rails.root.join("config/mx_mangle.yml")
  # Abbildung von Domain auf Name
  MANGLE_DOMAINS_MAP = MANGLE.inject({}){|h,f| f['domains'].each{|d| h[d] = f['name'] }; h }

  def domains
    total  = Domain.count
    result = Hash[Domain.select("dns_error, COUNT(*) AS count").with_error.group(:dns_error).map{|r| [r.dns_error, r.count] }]
    result.merge! \
      with_mx:    domains_mx_stats,
      without_mx: Domain.without_mx.without_error.count
  end

  # Gültigkeit der MX-Einträge
  def mx_validity
    result = {}
    Domain.mx_hosts.each do |host|
      validity = ICANN.fqdn_validity(host)
      result[validity] ||= 0
      result[validity]  += 1
    end
    result
  end

  # Anzahl Hosts pro Anzahl MX-Einträge
  def mx_counts
    connection
    .select_rows("SELECT COALESCE(array_length(mx_hosts,1),0) AS len, count(*) AS count FROM domains GROUP BY len ORDER BY len")
    .map{|row| row.map(&:to_i) }
    .to_h
  end

  def dnsstatus(table)
    connection
    .select_one("SELECT count(*) total, COUNT(CASE WHEN dns_secure THEN 1 ELSE null END) dns_secure, COUNT(dns_error!='') servfail, COUNT(dns_bogus) dns_bogus FROM #{table}")
    .map{|k,v| [k,v.to_i] }.to_h
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

  # Häufigste MX-Records
  def mx_providers(limit=20)
    # SELECT mx_addresses.hostname, mx_hosts.* from mx_hosts INNER JOIN mx_addresses ON mx_addresses.address=mx_hosts.address WHERE mx_addresses.hostname LIKE '%.emailsrvr.com' AND starttls IS NOT NULL;
    # SELECT unnest(mx_hosts), COUNT(*) from DOMAINS GROUP BY unnest(mx_hosts)
    result = {}
    Domain.with_mx.find_each batch_size: 50000 do |domain|
      unique_mx = Set.new
      domain.mx_hosts.each do |host|
        # strip domain
        parts = host.split(".")
        while parts.count > 2 do
          break if SECOND_LEVEL_DOMAINS.include? parts[1..-1].join(".")
          parts.shift
        end
        domain = parts.join(".")

        # mangle domain
        domain = MANGLE_DOMAINS_MAP.fetch(domain, domain)

        unique_mx.add domain
      end

      unique_mx.each do |mx|
        result[mx] ||= 0
        result[mx]  += 1
      end
    end

    # limit entries
    result = result.to_a.sort_by{|r| -r[1] }[0..limit]

    # merge entries with mangle entries
    result.map do |(name,count)|
      entry = MANGLE.find{|m| m['name'] == name } || {'name' => name, 'domains' => [name]}
      entry['count'] = count # Anzahl Domains

      # STARTTLS-Anteil ermitteln
      #where = entry['domains'].map{|d| "hostname LIKE " << connection.quote('%.'+d) }
      #entry.merge! MxHost.connection.select_one("SELECT sum(CASE WHEN starttls THEN 1 ELSE 0 END) AS starttls_count, COUNT(*) AS hosts_count
      #  FROM mx_hosts WHERE address IN (SELECT DISTINCT(address) FROM mx_addresses WHERE starttls IS NOT NULL AND (#{where.join ' OR '}))")
      entry
    end
  end

  def mx_address_stats
    addresses = MxRecord.connection.select_values("SELECT count(*) FROM mx_addresses GROUP BY address").map(&:to_i)

    result = {
      # Gesamtzahl von Hostnamen
      host_count:   MxRecord.count,
      host_with_ip: MxRecord.with_address.count,

      # Anzahl eindeutiger IP-Adressen
      ip_count:  addresses.count,

      # Durchnittliche Anzahl Hostnamen pro IP-Adresse
      hosts_per_ip: addresses.mean,

      # Hosts mit einer IP-Adresse
      #with_single_ip: addresses.inject(0){|sum,i| sum + (i==1 ? 1 : 0) },
    }

    # Anteil X an Gesamtzahl der Hostnamen
    {
      servfail:    MxRecord.without_address.with_error.count,
      without_ip:  MxRecord.without_address.without_error.count,
      ipv4_only:   select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_addresses AS outer_hosts WHERE family(address)=4 AND NOT EXISTS (SELECT 1 FROM mx_addresses WHERE hostname=outer_hosts.hostname AND family(address)=6)"),
      ipv6_only:   select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_addresses AS outer_hosts WHERE family(address)=6 AND NOT EXISTS (SELECT 1 FROM mx_addresses WHERE hostname=outer_hosts.hostname AND family(address)=4)"),
      ipv4and6:    select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_addresses AS outer_hosts WHERE family(address)=6 AND     EXISTS (SELECT 1 FROM mx_addresses WHERE hostname=outer_hosts.hostname AND family(address)=4)"),
    }.each do |key,count|
      result[key] = {
        count: count,
        share: (count.to_f / result[:host_count]).round(4)
      }
    end

    result
  end

  # Number of addresses per Scope
  def mx_address_scopes
    MxAddress.select("(CASE WHEN family(address)=4 THEN (address & inet '255.255.255.0') ELSE address END) AS addr, COUNT(*) AS count").group(:addr).inject({}) do |result,address|
      scope = address.addr.scope
      result[scope] ||= 0
      result[scope]  += address.count
      result
    end
  end

  def field_count(table, field)
    connection.select_rows("SELECT #{field}, COUNT(*) AS count FROM #{table} GROUP BY #{field} ORDER BY COUNT(*) DESC")
  end

  def hostnames_per_address_with_names(limit=50)
    hostnames_per_address(limit).map do |mx_record|
      {
        address: mx_record.address.to_s,
        count: mx_record.count,
        name: mx_record.reverse_name
      }
    end
  end

  def hostnames_per_address(limit=50)
    MxRecord.with_address.select("address, COUNT(*) AS count").group(:address).order("count DESC").limit(limit)
  end

  def issuers_count
    connection.select_value("SELECT COUNT(*) FROM (SELECT DISTINCT issuer_id FROM certificates) AS count")
  end

  def roots(limit=100)
    RawCertificate.select("raw_certificates.id, raw_certificates.raw, count(*) AS count").joins("INNER JOIN mx_hosts ON mx_hosts.root_certificate_id=raw_certificates.id").group(:id).order("count DESC")
  end

  def connection
    ActiveRecord::Base.connection
  end

  def select_int(sql)
    connection.select_value(sql).to_i
  end

end
