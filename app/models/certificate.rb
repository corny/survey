class Certificate < ActiveRecord::Base

  belongs_to :raw_certificate, foreign_key: :id

  delegate *%i(
    x509
    valid_for_name?
  ), to: :raw_certificate

end
