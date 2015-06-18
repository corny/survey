class CertificatesController < ApplicationController

  # most frequently used server certificates
  def top
    @mx_hosts = MxHost.top_certificates(50)
  end

  def show
    @certificate = RawCertificate.fingerprint(params[:id]).first!
  end

end
