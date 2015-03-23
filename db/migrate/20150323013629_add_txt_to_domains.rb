class AddTxtToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :txt, :string
  end
end
