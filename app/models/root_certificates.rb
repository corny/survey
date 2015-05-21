require 'csv'

class RootCertificates

  # Map from SHA1 fingerprint to owner
  def self.sha1_owners
    # source: https://docs.google.com/spreadsheet/ccc?key=0Ah-tHXMAwqU3dGx0cGFObG9QM192NFM4UWNBMlBaekE&usp=sharing
    @sha1_owners ||= mozilla_list.map do |row|
      [row["SHA-1 Fingerprint"].gsub(":","").downcase, row["Owner"]]
    end.to_h
  end

  def self.owners
    mozilla_list.map{|row| row["Owner"] }.uniq
  end

  def self.mozilla_list
    @CAs ||= parse_csv Rails.root.join("config/mozilla_CAs.csv")
  end

  def self.parse_csv(file)
    rows = []
    CSV.foreach file, headers: true do |row|
      rows << row
    end
    rows
  end

  def self.common_stats
    {
      owners: owners.count,
      in_nss: mozilla_list.select{|row| row["NSS Release When First Included"].present? }.count,
    }
  end

  class Group
    attr_reader :certs

    def initialize(certs, keys)
      @certs = certs
      @keys  = keys
    end

    def method_missing(m, *args, &block)
      if v = @keys[m]
        return v
      end
      super
    end

    def hosts_count
      certs.map(&:count).sum
    end

    def hosts_expired_count
      certs.map(&:expired_count).sum
    end

    def expired_ratio
      if (count = hosts_count) > 0
        hosts_expired_count.to_f / hosts_count
      else
        nil
      end
    end

    def intermediates_count
      certs.map(&:intermediates).map(&:count).sum
    end

    def used_count
      certs.select{|c| c.count > 0 }.count
    end

    def countries
      certs.map{|c| c.subject["C"].try(:first) }.compact.uniq.join(", ")
    end

    def to_h
      @keys.merge(
        countries:     countries,
        intermediates: intermediates_count,
        hosts:         hosts_count,
        expired:       expired_ratio,
        certificates: {
          total: certs.count,
          used:  used_count,
        }
      )
    end
  end

  Entry = Struct.new(:x509, :count, :expired_count, :missing) do
    delegate :subject, :key_size, :signature_algorithm, to: :x509
    def owner
      RootCertificates.sha1_owners[x509.sha1] || x509_owner
    end
    def x509_owner
      (subject["O"] || subject["CN"] || []).first
    end
    def intermediates
      RawCertificate.where("id IN (SELECT DISTINCT unnest(chain_intermediate_ids) FROM mx_hosts WHERE chain_root_id='\\x#{x509.sha1}')")
    end
    def intermediates_count
      intermediates.count
    end
  end

  attr_accessor :entries
  delegate :count, :each, to: :entries

  def initialize
    @unassigned = RawCertificate
    .select("raw_certificates.id, raw_certificates.raw, count(*) AS count, count(CASE WHEN cert_expired THEN 1 ELSE null END) expired_count")
    .joins("INNER JOIN mx_hosts ON mx_hosts.chain_root_id=raw_certificates.id")
    .group(:id)
    .map do |cert|
      [cert.id, cert]
    end.to_h

    @entries = Dir["/usr/share/ca-certificates/mozilla/*.crt"].map do |path|
      x509 = OpenSSL::X509::Certificate.new File.read(path)
      row  = @unassigned.delete(x509.sha1(binary: true))
      Entry.new x509, *( row ? [row.count, row.expired_count] : [0,0] )
    end

    @unassigned.values.each do |cert|
      Entry.new cert.x509, cert.count, cert.expired_count, true
    end

    @entries.sort_by!{|e| -e.count }
  end

  # Used certificates
  def used
    @entries.select{|e| e.count > 0 }
  end

  def by_signatures_keys
    @entries
    .group_by{|e| [e.signature_algorithm,e.key_size] }
    .sort_by{|key,_| key}
    .map{|key,certs| Group.new(certs, signature_algorithm: key[0], key_size: key[1])}
  end

  # grouped by owner and sorted descending by number of hosts
  def by_owners
    @entries
    .group_by(&:owner)
    .map{|owner,certs| Group.new certs, owner: owner }
    .sort_by{|grp| [-grp.hosts_count, grp.owner.downcase] }
  end

end