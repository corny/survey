class RootCertificates

  ORG_MANGLE = YAML.load_file(Rails.root.join("config/ca_mangle.yml")).each do |h|
    # Create case-insensitive Regexp instances
    h['regex'] = Regexp.new(h['regex'],"i")
  end

  OrganizationGroup = Struct.new(:name, :certs) do
    def hosts_count
      certs.map(&:count).sum
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
      {
        name:          name,
        hosts_count:   hosts_count,
        intermediates: intermediates_count,
        countries:     countries,
        certificates: {
          total: certs.count,
          used:  used_count,
        }
      }
    end
  end

  Entry = Struct.new(:x509, :count, :missing) do
    delegate :subject, :key_size, :signature_algorithm, to: :x509
    def organization
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
    .select("raw_certificates.id, raw_certificates.raw, count(*) AS count")
    .joins("INNER JOIN mx_hosts ON mx_hosts.chain_root_id=raw_certificates.id")
    .group(:id)
    .map do |cert|
      [cert.id, cert]
    end.to_h

    @entries = Dir["/usr/share/ca-certificates/mozilla/*.crt"].map do |path|
      x509 = OpenSSL::X509::Certificate.new File.read(path)
      Entry.new x509, @unassigned.delete(x509.sha1(binary: true)).try(:count) || 0
    end

    @unassigned.values.each do |cert|
      Entry.new cert.x509, cert.count, true
    end

    @entries.sort_by!{|e| -e.count }
  end

  # Used certificates
  def used
    @entries.select{|e| e.count > 0 }
  end

  def by_signature_and_keysize
    @entries.group_by{|e| [e.signature_algorithm,e.key_size] }.sort_by{|key,_| key}
  end

  def mangle_organization(name)
    name.force_encoding("utf-8")
    ORG_MANGLE.each do |h|
      return h['name'] if name =~ h['regex']
    end
    name
  end

  # grouped by organization and sorted descending by number of hosts
  def by_organization
    @entries
    .group_by{|e| mangle_organization(e.organization) }
    .map{|name,certs| OrganizationGroup.new name, certs }
    .sort_by{|grp| [-grp.hosts_count, grp.name.downcase] }
  end

end