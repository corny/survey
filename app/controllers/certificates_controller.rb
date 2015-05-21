class CertificatesController < ApplicationController

  def show
    @certificate = RawCertificate.fingerprint(params[:id]).first!
  end

end
