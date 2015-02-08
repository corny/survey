class AddColumnsToMxHosts < ActiveRecord::Migration
  def change
    change_table :mx_hosts do |t|
      t.boolean :starttls
      t.boolean :cert_valid, index: true
      t.references :certificate, index: true
    end

    add_foreign_key :mx_hosts, :certificates
  end
end
