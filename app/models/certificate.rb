class Certificate < ActiveRecord::Base
  include SelectHelper

  belongs_to :raw_certificate, foreign_key: :id

  # Wird als Server-Zertifikat verwendet
  scope :leaf,   ->{ where "id IN (SELECT DISTINCT(certificate_id) FROM mx_hosts)" }

  # Wird als Root/Zwischenzertifikat verwendet
  scope :issuer, ->{ where "id IN (SELECT DISTINCT(id) FROM ca_certificate_ids)" }

  delegate *%i(
    x509
    valid_for_name?
  ), to: :raw_certificate

  def self.by_signatures_keys
    select("COUNT(*) AS count, signature_algorithm")
    .group(:signature_algorithm)
    .order(:signature_algorithm)
  end

  def signature_algorithm_name
    Names.signature_algorithm(signature_algorithm)
  end

  # Erstellt eine Auswertung über einen Zeitraum
  # und füllt Lücken mit Nullen auf.
  def self.keysize_over_time(field, daterange)
    rows = where("(not_after - days_valid) >= ? AND (not_after - days_valid) <= ?", daterange.begin, daterange.end)
    .select("EXTRACT(YEAR FROM (not_after - days_valid)) AS year, EXTRACT(MONTH FROM (not_after - days_valid)) AS month, #{field} AS key, COUNT(*) AS count")
    .group("year, month, #{field}")
    .to_a

    keys   = rows.map(&:key).uniq.sort
    result = [["year", "month", *keys]]
    date   = daterange.begin
    while date <= daterange.end
      year, month = date.year, date.month
      month_rows  = rows.select{|r| r.year==year && r.month==month }
      result << [date.year, date.month, *keys.map{|k| month_rows.find{|r| r.key == k}.try(:count) || 0 } ]
      date >>= 1
    end
    result
  end

end
