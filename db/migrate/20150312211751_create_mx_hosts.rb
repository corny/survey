class CreateMxHosts < ActiveRecord::Migration
  def change
    create_table :mx_hosts do |t|
      t.inet   :address, null: false
      t.string :error, index: true

      t.boolean :starttls
      t.column  :tls_version,      :tls_version,      index: true
      t.column  :tls_cipher_suite, :tls_cipher_suite, index: true
      t.boolean :cert_valid, index: true
      t.binary  :certificate_id, index: true
      t.binary  :ca_certificate_ids, array: true, index: true
      t.datetime :updated_at, null: false
    end

    add_index :mx_hosts, :address, unique: true
  end
end
