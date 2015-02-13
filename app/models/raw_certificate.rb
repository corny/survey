class RawCertificate < ActiveRecord::Base

  delegate \
    :public_key,
    :subject,
    :issuer,
    to: :x509

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
          key_id:           x509.public_key.hash,
          is_valid:         false,
          is_self_signed:   x509.issuer == x509.subject,
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

  def key_size
    key = public_key
    case key
    when OpenSSL::PKey::RSA
      key.n.num_bits
    when OpenSSL::PKey::DSA
      key.p.num_bits
    when OpenSSL::PKey::EC
      # don't know better
      public_key.to_text.match(%r((\d+) bit))[1].to_i
    end
  end

  def key_type
    public_key.class.to_s.split("::").last
  end

end
