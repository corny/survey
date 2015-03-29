class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates, id: false do |t|
      t.binary :id,               null: false
      t.binary :subject_id,       null: false, index: true
      t.binary :issuer_id,        null: false, index: true
      t.binary :key_id,           null: false, index: true
      t.integer :key_size,                     index: true
      t.boolean :is_ca
      t.boolean :is_valid
      t.boolean :is_self_signed
      t.string :validation_error
      t.timestamp :first_seen_at, null: false
    end

    execute "ALTER TABLE certificates ADD PRIMARY KEY (id)"
    add_foreign_key :certificates, :raw_certificates, column: :id
  end
end