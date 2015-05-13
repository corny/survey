class CreateMxHosts < ActiveRecord::Migration
  def change
    create_table :mx_hosts do |t|
      t.inet   :address, null: false
      t.string :error, index: true

      t.boolean :starttls
      t.binary  :tls_versions,      array: true, index: true
      t.binary  :tls_cipher_suites, array: true, index: true
      t.boolean :cert_valid, index: true
      t.boolean :cert_expired, index: true
      t.binary  :certificate_id, index: true
      t.binary  :ca_certificate_ids, array: true, index: true
      t.integer :dh_prime_size,                   index: true
      t.datetime :updated_at, null: false
    end

    add_index :mx_hosts, :address, unique: true
  end
end
