class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.text :mx_hosts, array: true, default: [], index: true
      t.string :error, index: true
      t.string :dnssec, index: true
    end
    add_index :domains, :name, unique: true
  end
end
