module Issuers

  def self.list(limit=100)
    Certificate.select("issuer_id, count(*) AS count").group(:issuer_id).order("count DESC").limit(limit).map do |cert|
      Issuer.new cert.issuer_id, cert.count
    end
  end

  Issuer = Struct.new(:sha1,:count) do
    def name
      @name ||= certificates.first!.x509.issuer
    end

    def sha1_hex
      sha1.unpack('H*')[0]
    end

    def to_h
      h = {
        certificates: count,
        name:         name.to_a.map{|a,b| [a,b] }.to_h,
      }
      %w( days_valid_mean days_valid_median trusted_hosts_ratio expired_hosts_ratio ).inject(h) do |h,key|
        h[key] = send(key)
        h
      end
    end

    def days_valid_median
      ActiveRecord::Base.connection.select_one \
      "SELECT
              t1.n + t2.n + t3.n + t4.n AS n,
              t1.min_valid AS q1,
              t2.min_valid AS q2,
              t2.med_valid AS med,
              t3.max_valid AS q3,
              t4.max_valid AS q4
      FROM certificate_statistics_quantiles t1
      INNER JOIN certificate_statistics_quantiles t2 ON t1.issuer_id=t2.issuer_id AND t2.q=2
      INNER JOIN certificate_statistics_quantiles t3 ON t1.issuer_id=t3.issuer_id AND t3.q=3
      INNER JOIN certificate_statistics_quantiles t4 ON t1.issuer_id=t4.issuer_id AND t4.q=4
      WHERE t1.q=1 AND t1.issuer_id=E'\\\\x#{sha1_hex}'"
    end

    def days_valid_mean
      row = certificates.pluck("AVG(days_valid), STDDEV_POP(days_valid)")[0]
      {
        mean:   row[0].to_f,
        stddev: row[1].to_f
      }
    end

    def mx_stats
      @mx_stats ||= MxHost
      .where("certificate_id IN (SELECT id FROM certificates WHERE issuer_id=E?)", "\\\\x#{sha1_hex}")
      .select("COUNT(CASE WHEN cert_expired THEN 1 ELSE null END) AS expired, COUNT(CASE WHEN cert_trusted THEN 1 ELSE null END) AS trusted, COUNT(*) AS count")[0]
    end

    def expired_hosts_ratio
      @expired ||= mx_stats.expired.to_f / mx_stats.count
    end

    def trusted_hosts_ratio
      @trusted ||= mx_stats.trusted.to_f / mx_stats.count
    end

    def certificates
      Certificate.where(issuer_id: sha1)
    end
  end

end
