# This is just a VIEW of mx_records
class MxAddress < ActiveRecord::Base

  #  hostnames | addresses
  # -----------+-----------
  #          1 |    279261 -- 279261 Adressen haben einen einzigen Hostnamen
  #          2 |     36297 --  36297 Adressen haben 2 Hostnamen
  #          3 |     11230 --  11230 Adressen haben 3 Hostnamen
  def self.distribution
    connection.select_all <<-SQL.squish
      WITH tmp AS ( SELECT count(*) AS hostnames FROM mx_addresses GROUP BY address)
      SELECT hostnames, COUNT(*) AS addresses
      FROM tmp
      GROUP BY hostnames
      ORDER BY hostnames
    SQL
  end

end
