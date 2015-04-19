class CreateMxDomains < ActiveRecord::Migration
  def change
    create_table :mx_domains do |t|
      t.string  :name, null: false
      t.string :txt
      t.datetime :updated_at, index: true
    end
    add_index :mx_domains, :name, unique: true
  end
end
