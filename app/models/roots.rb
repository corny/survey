class Roots

  Entry = Struct.new(:x509, :count) do
    delegate :subject, :key_size, :signature_algorithm, to: :x509
    def organization
      (subject["O"] || subject["CN"] || []).first
    end
  end

  attr_accessor :entries
  delegate :count, :each, to: :entries

  def initialize
    @unassigned = RawCertificate
    .select("raw_certificates.id, raw_certificates.raw, count(*) AS count")
    .joins("INNER JOIN mx_hosts ON mx_hosts.root_certificate_id=raw_certificates.id")
    .group(:id)
    .map do |cert|
      [cert.id, cert]
    end.to_h

    @entries = Dir["/usr/share/ca-certificates/mozilla/*.crt"].map do |path|
      x509 = OpenSSL::X509::Certificate.new File.read(path)
      Entry.new x509, @unassigned.delete(x509.sha1(binary: true)).try(:count) || 0
    end

    @entries.sort_by!{|e| -e.count }
  end

  def unassigned
    @unassigned.values
  end

  # Used certificates
  def used
    @entries.select{|e| e.count > 0 }
  end

  def by_signature_and_keysize
    @entries.group_by{|e| [e.signature_algorithm,e.key_size] }.sort_by{|key,_| key}
  end

  # grouped by organization and sorted descending by number of hosts
  def by_organization
    @entries.group_by(&:organization).sort_by{|k,v| [-v.map(&:count).sum, k.downcase] }
  end

end