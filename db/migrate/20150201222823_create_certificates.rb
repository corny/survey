class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.column :sha1_fingerprint, :bytea, null: false
      t.boolean :is_valid,       null: false
      t.boolean :is_self_signed, null: false
      t.string :validation_error
      t.text :names, array: true, default: [], null: false
      t.timestamp :first_seen_at, null: false
    end

    add_foreign_key :certificates, :raw_certificates, column: :id
  end
end
