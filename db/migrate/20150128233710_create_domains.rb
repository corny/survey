class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string  :name, null: false
      t.text    :mx_hosts, array: true, default: [], index: true

      t.boolean :dns_secure, index: true
      t.string  :dns_error
      t.string  :dns_bogus

      t.datetime :updated_at, index: true
    end
    add_index :domains, :name, unique: true
  end
end
