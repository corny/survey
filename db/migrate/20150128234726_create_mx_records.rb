class CreateMxRecords < ActiveRecord::Migration
  def change
    create_table :mx_records, id: false do |t|
      t.string :hostname, null: false, index: true
      t.inet   :address

      t.boolean :dns_secure, index: true
      t.string  :dns_error
      t.string  :dns_bogus

      t.boolean :cert_matches, index: true
    end

    add_index :mx_records, [:address, :hostname], unique: true
  end
end
