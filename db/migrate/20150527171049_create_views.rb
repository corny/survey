class CreateViews < ActiveRecord::Migration
  def change
    execute <<-SQL.squish

CREATE MATERIALIZED VIEW certificate_statistics_quantiles AS (
        SELECT
                issuer_id, q, COUNT(*) AS n,
                min(days_valid) AS min_valid,
                max(case when bitile=1 then days_valid else 0 end) as med_valid,
                max(days_valid) AS max_valid
        FROM (
                SELECT
                        q, issuer_id, days_valid,
                        ntile(2) OVER (PARTITION BY issuer_id ORDER BY days_valid) AS bitile
                FROM (
                        SELECT issuer_id, days_valid, ntile(4) OVER (ORDER BY days_valid) AS q
                        FROM certificates
                ) x1
        ) x2
        GROUP BY issuer_id, q
        ORDER BY issuer_id, q
)
    SQL
    execute "CREATE INDEX certificate_statistics_issuer_id ON certificate_statistics_quantiles (issuer_id)"
  end
end
