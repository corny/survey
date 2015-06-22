class MxHost < ActiveRecord::Base
  include SelectHelper

  has_many :mx_records,
    foreign_key: :address,
    primary_key: :address

  belongs_to :certificate, foreign_key: :certificate_id, class_name: 'RawCertificate'
  belongs_to :root_certificate, foreign_key: :root_certificate_id, class_name: 'RawCertificate'

  scope :without_error,     ->{ where "error IS null"}
  scope :with_tls,          ->{ where "tls_versions IS NOT null" }
  scope :with_starttls,     ->{ where "starttls IS true" }
  scope :with_certificates, ->{ where "certificate_id IS NOT null" }
  scope :with_mx_record,    ->{ where "address IN (SELECT DISTINCT(address) FROM mx_addresses WHERE address IS NOT null)" }
  scope :with_hostnames,    ->(hostnames){ where "address IN (SELECT address FROM mx_records WHERE " << (["hostname ILIKE ?"]*hostnames.count).join(" OR ") << ")", *hostnames }
  scope :ipv4,              ->{ where "family(address)=4" }

  scope :with_multiple_used_certificate, -> {
    where "certificate_id IN (SELECT certificate_id FROM mx_hosts WHERE certificate_id IS NOT null GROUP BY certificate_id HAVING count(*) > 1)"
  }
  scope :with_once_used_certificate, -> {
    where "certificate_id IN (SELECT certificate_id FROM mx_hosts WHERE certificate_id IS NOT null GROUP BY certificate_id HAVING count(*) = 1)"
  }

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

  def self.tls_versions
    where("tls_versions IS NOT NULL").select("tls_versions, COUNT(*) AS count").group(:tls_versions).order(:tls_versions)
  end

  def self.tls_cipher_suites
    where("tls_cipher_suites IS NOT NULL").select("tls_cipher_suites, COUNT(*) AS count").group(:tls_cipher_suites).order(:tls_cipher_suites)
  end

  def self.top_certificates(limit)
    with_certificates
    .select('certificate_id, count(*) AS count, COUNT(CASE WHEN cert_trusted THEN 1 ELSE null END) AS count_cert_trusted, BOOL_OR(cert_expired) AS cert_expired')
    .group(:certificate_id)
    .order('count DESC')
    .limit(limit)
  end

  def self.errors
    errors = {}
    select("error, count(*) AS count")
    .group(:error)
    .each do |row|
      error = row['error']
      error = case error
      when /^tls: received record with version (\d+) when expecting version (\d+)/
        "tls: received record with version ... when expecting version ..."
      when /oversized record received with length \d+/
        "tls: oversized record received with length ..."
      when /^tls: failed to parse certificate from server/
        "tls: failed to parse certificate from server: ..."
      else
        error
      end

      errors[error] ||= 0
      errors[error] +=  row['count']
    end
    errors.sort_by{|_,v| -v}
  end

end
