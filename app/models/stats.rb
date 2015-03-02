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
