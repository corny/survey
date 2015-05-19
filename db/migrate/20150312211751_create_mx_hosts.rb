class CreateMxHosts < ActiveRecord::Migration
  def change
    create_table :mx_hosts do |t|
      t.inet   :address, null: false
      t.string :error, index: true

      t.boolean :starttls,                       index: true
      t.binary  :tls_versions,      array: true, index: true
      t.binary  :tls_cipher_suites, array: true, index: true
      t.boolean :cert_trusted,                   index: true
      t.boolean :cert_expired,                   index: true
      t.string  :cert_error,                     index: true
      t.binary  :certificate_id,                  index: true
      t.binary  :ca_certificate_ids, array: true, index: true # received itermediate/root certificates
      t.binary  :root_certificate_id,             index: true # root certificate for a valid chain
      t.integer :ecdhe_curve_type,                index: true
      t.integer :ecdhe_curve_id,                  index: true
      t.datetime :updated_at, null: false
    end

    add_index :mx_hosts, :address, unique: true
  end
end
