class CreateMxRecords < ActiveRecord::Migration
  def change
    create_table :mx_records do |t|
      t.string :hostname, null: false
      t.inet   :address
      t.string :dnserr, index: true
      t.string :dnssec, index: true
      t.boolean :cert_matches, index: true
    end

    add_index :mx_records, [:address, :hostname], unique: true
  end
end
