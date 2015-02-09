class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.binary :sha1_fingerprint, null: false
      t.column :subject_id, :bigint, null: false, index: true
      t.column :issuer_id,  :bigint, null: false, index: true
      t.boolean :is_valid,       null: false
      t.boolean :is_self_signed, null: false
      t.string :validation_error
      t.timestamp :first_seen_at, null: false
    end

    add_foreign_key :certificates, :raw_certificates, column: :id
  end
end
