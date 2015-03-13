require 'zgrab'

module Importer

  def self.import(json)
    result = Zgrab::Result.new(json)
    if result.certificates
      certs       = result.certificates.map{ |cert| RawCertificate.find_or_create cert, seen_at: result.time }
      certificate = certs.first
    else
      certificate = nil
    end

    MxHost.transaction do
      host = MxHost.find_or_initialize_by(address: result.host)
      host.update_attributes! \
        error:            result.error,
        starttls:         result.starttls?,
        tls_cipher_suite: result.tls_cipher_suite,
        tls_version:      result.tls_version,
        cert_valid:       result.certificate_valid?,
        certificate_id:   certificate.try(:id)
      
      begin
        MxRecord.where(address: result.host).each do |record|
          record.update_attributes \
            cert_matches: certificate.try(:valid_for_name?, record.hostname)
        end
      rescue OpenSSL::OpenSSLError
        STDERR.puts $!.inspect
      end
    end

    result
  end

end