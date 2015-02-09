class AddColumnsToMxHosts < ActiveRecord::Migration
  def change
    change_table :mx_hosts do |t|
      t.boolean :starttls
      t.column  :tls_version,      :tls_version,      index: true
      t.column  :tls_cipher_suite, :tls_cipher_suite, index: true
      t.boolean :cert_valid, index: true
      t.references :certificate, index: true
    end

    add_foreign_key :mx_hosts, :certificates
  end
end
