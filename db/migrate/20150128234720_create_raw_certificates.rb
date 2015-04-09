class CreateRawCertificates < ActiveRecord::Migration
  def change
    create_table :raw_certificates, id: false do |t|
      t.binary :id,  null: false
      t.binary :raw, null: false
    end

    execute "ALTER TABLE raw_certificates ADD PRIMARY KEY (id)"
  end
end
