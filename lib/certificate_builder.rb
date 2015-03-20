module CertificateBuilder

  def self.build(common_names)
    # http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/X509/Certificate.html#label-Creating+a+root+CA+certificate+and+an+end-entity+certificate
    cert            = OpenSSL::X509::Certificate.new
    cert.version    = 2 # cf. RFC 5280 - to make it a "v3" certificate
    cert.serial     = 1
    cert.subject    = OpenSSL::X509::Name.new [['CN', common_names[0]]]
    cert.issuer     = cert.subject # root CA's are "self-signed"
    cert.public_key = key.public_key
    cert.not_before = 1.day.ago
    cert.not_after  = cert.not_before + 1.year
    cert.sign(key, OpenSSL::Digest::SHA256.new)

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate  = cert
    cert.add_extension ef.create_extension("subjectAltName", common_names.map{|d| "DNS: #{d}" }.join(','))

    cert
  end

  def self.key
    @key ||= OpenSSL::PKey::RSA.new 1024 # public/private key
  end

end