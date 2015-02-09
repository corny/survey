class CreateRawCertificates < ActiveRecord::Migration
  def change
    create_table :raw_certificates do |t|
      t.binary :sha1_fingerprint, null: false
      t.binary :raw,              null: false
    end

    add_index :raw_certificates, :sha1_fingerprint, unique: true
  end
end
