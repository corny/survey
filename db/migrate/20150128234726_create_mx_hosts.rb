class CreateMxHosts < ActiveRecord::Migration
  def change
    create_table :mx_hosts do |t|
      t.string :hostname, null: false
      t.inet :address, null: false
    end

    add_index :mx_hosts, [:address, :hostname], unique: true
  end
end
