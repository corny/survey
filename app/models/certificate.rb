class Certificate < ActiveRecord::Base

  belongs_to :raw_certificate, foreign_key: :id

  delegate :x509, to: :raw_certificate

end
