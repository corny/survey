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

ActiveRecord::Schema.define(version: 20150128234726) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", force: :cascade do |t|
    t.binary   "sha1_fingerprint",           null: false
    t.integer  "subject_id",       limit: 8, null: false
    t.integer  "issuer_id",        limit: 8, null: false
    t.integer  "key_id",           limit: 8, null: false
    t.integer  "key_size"
    t.boolean  "is_valid",                   null: false
    t.boolean  "is_self_signed",             null: false
    t.string   "validation_error"
    t.datetime "first_seen_at",              null: false
  end

  add_index "certificates", ["issuer_id"], name: "index_certificates_on_issuer_id", using: :btree
  add_index "certificates", ["key_id"], name: "index_certificates_on_key_id", using: :btree
  add_index "certificates", ["key_size"], name: "index_certificates_on_key_size", using: :btree
  add_index "certificates", ["subject_id"], name: "index_certificates_on_subject_id", using: :btree

  create_table "domains", force: :cascade do |t|
    t.string "name",                  null: false
    t.text   "mx_hosts", default: [],              array: true
    t.string "error"
  end

  add_index "domains", ["error"], name: "index_domains_on_error", using: :btree
  add_index "domains", ["mx_hosts"], name: "index_domains_on_mx_hosts", using: :btree
  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree

# Could not dump table "mx_hosts" because of following StandardError
#   Unknown type 'tls_version' for column 'tls_version'

  create_table "raw_certificates", force: :cascade do |t|
    t.binary "sha1_fingerprint", null: false
    t.binary "raw",              null: false
  end

  add_index "raw_certificates", ["sha1_fingerprint"], name: "index_raw_certificates_on_sha1_fingerprint", unique: true, using: :btree

  add_foreign_key "certificates", "raw_certificates", column: "id"
  add_foreign_key "mx_hosts", "certificates"
end
