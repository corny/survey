class MxHost < ActiveRecord::Base

  has_many :mx_records,
    foreign_key: :address,
    primary_key: :address

  belongs_to :certificate, foreign_key: :certificate_id, class_name: 'RawCertificate'

end
