class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.text :mx_hosts, array: true, default: []
      t.string :error, index: true
    end
    add_index :domains, :name, unique: true
    add_index :domains, :mx_hosts
  end
end
