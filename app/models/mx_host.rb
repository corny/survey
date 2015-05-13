class MxHost < ActiveRecord::Base

  has_many :mx_records,
    foreign_key: :address,
    primary_key: :address

  belongs_to :certificate, foreign_key: :certificate_id, class_name: 'RawCertificate'

  CIPHER_SUITES = YAML.load_file(Rails.root.join "config/cipher_suites.yml")
  TLS_VERSIONS = {
        0x0300 => "SSLv3",
        0x0301 => "TLSv1.0",
        0x0302 => "TLSv1.1",
        0x0303 => "TLSv1.2",
  }

  def tls_version_names
    tls_versions.map{|v| TLS_VERSIONS[v.unpack('n').first] || v }
  end

  def tls_cipher_suite_names
    tls_cipher_suites.map{|v| CIPHER_SUITES[v.unpack('n').first] || v }
  end

end
