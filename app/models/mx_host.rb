class MxHost < ActiveRecord::Base

  belongs_to :certificate, foreign_key: :certificate_id, class_name: 'RawCertificate'

end
