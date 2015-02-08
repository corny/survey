class RawCertificate < ActiveRecord::Base

  scope :fingerprint, ->(val) do
    where "sha1_fingerprint=E?", "\\\\x#{val}"
  end

  def self.find_or_create(x509, seen_at: Time.now)
    transaction do
      sha1 = x509.sha1 binary: true
      cert = fingerprint(bin2hex(sha1)).first
      unless cert
        cert = create! \
          sha1_fingerprint: sha1,
          raw:              x509.to_der.force_encoding('binary')

        Certificate.create! \
          id:               cert.id,
          sha1_fingerprint: sha1,
          issuer_id:        x509.issuer.hash,
          subject_id:       x509.subject.hash,
          is_valid:         false,
          is_self_signed:   false,
          first_seen_at:    seen_at
      end
      cert
    end
  end

  def self.bin2hex(val)
    val.unpack('H*')[0]
  end

  def x509
    @x509 ||= OpenSSL::X509::Certificate.new(raw)
  end

end
