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
    result = Hash[Domain.select("error, COUNT(*) AS count").with_error.group(:error).map{|r| [r.error, r.count] }]
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
    Hash[Domain.select("COALESCE(array_length(mx_hosts,1),0) AS len, count(*) AS count").group(:len).map{|r| [r.len, r.count] }]
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
  def mx_charts(limit=20)
    # SELECT unnest(mx_hosts), COUNT(*) from DOMAINS GROUP BY unnest(mx_hosts)
    result = {}
    Domain.with_mx.find_each batch_size: 10000 do |domain|
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
    top = result.to_a.sort_by{|r| -r[1] }[0..limit]

    # merge entries with mangle entries
    top.map do |(name,count)|
      entry = MANGLE.find{|m| m['name'] == name } || {'name' => name}
      entry.merge 'count' => count
    end
  end

  def mx_address_stats
    addresses = MxRecord.connection.select_values("SELECT count(*) FROM mx_records WHERE address IS NOT null GROUP BY address").map(&:to_i)

    result = {
      # Gesamtzahl von Hostnamen
      host_count:   select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_records"),
      host_with_ip: select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_records WHERE address IS NOT null"),

      # Anzahl eindeutiger IP-Adressen
      ip_count:  addresses.count,

      # Durchnittliche Anzahl Hostnamen pro IP-Adresse
      hosts_per_ip: addresses.mean,

      # Hosts mit einer IP-Adresse
      #with_single_ip: addresses.inject(0){|sum,i| sum + (i==1 ? 1 : 0) },
    }

    # Anteil X an Gesamtzahl der Hostnamen
    {
      without_ip:  MxRecord.without_address.without_error.count,
      servfail:    MxRecord.without_address.with_error.count,
      ipv4_only:   select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_records AS outer_hosts WHERE family(address)=4 AND NOT EXISTS (SELECT 1 FROM mx_records WHERE hostname=outer_hosts.hostname AND family(address)=6)"),
      ipv6_only:   select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_records AS outer_hosts WHERE family(address)=6 AND NOT EXISTS (SELECT 1 FROM mx_records WHERE hostname=outer_hosts.hostname AND family(address)=4)"),
      ipv4and6:    select_int("SELECT COUNT(DISTINCT(hostname)) FROM mx_records AS outer_hosts WHERE family(address)=6 AND     EXISTS (SELECT 1 FROM mx_records WHERE hostname=outer_hosts.hostname AND family(address)=4)"),
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
    MxRecord.with_address.uniq.pluck(:address).inject({}) do |result,address|
      scope = address.scope
      result[scope] ||= 0
      result[scope]  += 1
      result
    end
  end

  def tls_versions
    MxHost.where("tls_version IS NOT NULL").select("tls_version, COUNT(*) AS count").group(:tls_version).order(:tls_version)
  end

  def certificate_field_count(field)
    ActiveRecord::Base.connection.select_rows("SELECT #{field}, COUNT(*) AS count FROM certificates GROUP BY #{field} ORDER BY COUNT(*) DESC")
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

  X509Name = Struct.new(:sha1,:count) do
    def name
      @name ||= Certificate.where(issuer_id: sha1).first!.x509.issuer
    end
  end

  def issuers_count
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM (SELECT DISTINCT issuer_id FROM certificates) AS count");
  end

  def issuers(limit=100)
    Certificate.select("issuer_id, count(*) AS count").group(:issuer_id).order("count DESC").limit(limit).map do |cert|
      X509Name.new cert.issuer_id, cert.count
    end
  end

  def select_int(sql)
    ActiveRecord::Base.connection.select_value(sql).to_i
  end

end
