class Certificate < ActiveRecord::Base
  include SelectHelper

  belongs_to :raw_certificate, foreign_key: :id

  delegate *%i(
    x509
    valid_for_name?
  ), to: :raw_certificate

  def self.by_signatures_keys
    select("COUNT(*) AS count, signature_algorithm")
    .group(:signature_algorithm)
    .order(:signature_algorithm)
  end

end
