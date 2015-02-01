class CreateRawCertificates < ActiveRecord::Migration
  def change
    create_table :raw_certificates do |t|
      t.column :sha1_fingerprint, :bytea, null: false
      t.column :raw,              :bytea, null: false
    end
  end
end
