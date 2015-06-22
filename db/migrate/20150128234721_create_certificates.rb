class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates, id: false do |t|
      t.binary  :id,                   null: false
      t.binary  :subject_id,           null: false, index: true
      t.binary  :issuer_id,            null: false, index: true
      t.binary  :key_id,               null: false, index: true
      t.integer :key_size,                          index: true
      t.string  :key_algorithm,        null: false, index: true
      t.string  :signature_algorithm,  null: false, index: true
      t.boolean :is_ca,                             index: true
      t.boolean :is_self_signed,                    index: true
      t.integer :days_valid,                        index: true
      t.timestamp :first_seen_at, null: false
      t.date      :not_after, index: true
    end

    execute "ALTER TABLE certificates ADD PRIMARY KEY (id)"
    add_foreign_key :certificates, :raw_certificates, column: :id
  end
end
