# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150312211751) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", force: :cascade do |t|
    t.binary   "subject_id",           null: false
    t.binary   "issuer_id",            null: false
    t.binary   "key_id",               null: false
    t.integer  "key_size"
    t.string   "signature_algorithm"
    t.string   "public_key_algorithm"
    t.boolean  "is_ca"
    t.boolean  "is_valid"
    t.boolean  "is_self_signed"
    t.string   "validation_error"
    t.datetime "first_seen_at",        null: false
  end

  add_index "certificates", ["issuer_id"], name: "index_certificates_on_issuer_id", using: :btree
  add_index "certificates", ["key_id"], name: "index_certificates_on_key_id", using: :btree
  add_index "certificates", ["key_size"], name: "index_certificates_on_key_size", using: :btree
  add_index "certificates", ["public_key_algorithm"], name: "index_certificates_on_public_key_algorithm", using: :btree
  add_index "certificates", ["signature_algorithm"], name: "index_certificates_on_signature_algorithm", using: :btree
  add_index "certificates", ["subject_id"], name: "index_certificates_on_subject_id", using: :btree

  create_table "domains", force: :cascade do |t|
    t.string   "name",                    null: false
    t.text     "mx_hosts",   default: [],              array: true
    t.boolean  "dns_secure"
    t.string   "dns_error"
    t.string   "dns_bogus"
    t.datetime "updated_at"
  end

  add_index "domains", ["dns_secure"], name: "index_domains_on_dns_secure", using: :btree
  add_index "domains", ["mx_hosts"], name: "index_domains_on_mx_hosts", using: :btree
  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree
  add_index "domains", ["updated_at"], name: "index_domains_on_updated_at", using: :btree

  create_table "mx_domains", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "txt"
    t.datetime "updated_at"
  end

  add_index "mx_domains", ["name"], name: "index_mx_domains_on_name", unique: true, using: :btree
  add_index "mx_domains", ["updated_at"], name: "index_mx_domains_on_updated_at", using: :btree

# Could not dump table "mx_hosts" because of following StandardError
#   Unknown type 'tls_version' for column 'tls_version'

  create_table "mx_records", id: false, force: :cascade do |t|
    t.string  "hostname",     null: false
    t.inet    "address"
    t.boolean "dns_secure"
    t.string  "dns_error"
    t.string  "dns_bogus"
    t.boolean "cert_matches"
  end

  add_index "mx_records", ["address", "hostname"], name: "index_mx_records_on_address_and_hostname", unique: true, using: :btree
  add_index "mx_records", ["cert_matches"], name: "index_mx_records_on_cert_matches", using: :btree
  add_index "mx_records", ["dns_secure"], name: "index_mx_records_on_dns_secure", using: :btree
  add_index "mx_records", ["hostname"], name: "index_mx_records_on_hostname", using: :btree

  create_table "raw_certificates", force: :cascade do |t|
    t.binary "raw", null: false
  end

  add_foreign_key "certificates", "raw_certificates", column: "id"
end
