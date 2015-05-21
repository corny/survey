class RawCertificate < ActiveRecord::Base

  delegate \
    :public_key,
    :subject,
    :issuer,
    :extensions,
    to: :x509

  scope :fingerprint, ->(val) do
    where "id=E?", "\\\\x#{val}"
  end

  has_one :certificate,
    foreign_key: :id,
    primary_key: :id

  def self.find_or_create(x509, seen_at: Time.now)
    transaction do
      sha1 = x509.sha1 binary: true
      cert = fingerprint(bin2hex(sha1)).first
      unless cert
        cert = create! \
          id:   sha1,
          raw:  x509.to_der.force_encoding('binary')

        Certificate.create! \
          id:               sha1,
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

  def valid_for_name?(name)
    OpenSSL::SSL.verify_certificate_identity(x509, name)
  end

  def names
    # subject alt names have precedence over common names
    subject_alt_names || common_names
  end

  def subject_alt_names
    if e = extensions.find{|e| e.oid == 'subjectAltName' }
      e.value.split(",").map{|c| c.strip.gsub(/^DNS:/, "") }
    end
  end

  def common_names
    subject.to_a.map{|a| a[1] if a[0]=='CN' }.compact
  end

  def key_type
    public_key.class.to_s.split("::").last
  end

end
