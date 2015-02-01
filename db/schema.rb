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

ActiveRecord::Schema.define(version: 20150201222830) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", force: :cascade do |t|
    t.binary   "sha1_fingerprint",              null: false
    t.boolean  "is_valid",                      null: false
    t.boolean  "is_self_signed",                null: false
    t.string   "validation_error"
    t.text     "names",            default: [], null: false, array: true
    t.datetime "first_seen_at",                 null: false
  end

  create_table "domains", force: :cascade do |t|
    t.string "name",                  null: false
    t.text   "mx_hosts", default: [],              array: true
  end

  add_index "domains", ["mx_hosts"], name: "index_domains_on_mx_hosts", using: :btree
  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree

  create_table "mx_hosts", force: :cascade do |t|
    t.string  "hostname",       null: false
    t.inet    "address",        null: false
    t.boolean "starttls"
    t.integer "certificate_id"
  end

  add_index "mx_hosts", ["address", "hostname"], name: "index_mx_hosts_on_address_and_hostname", unique: true, using: :btree
  add_index "mx_hosts", ["certificate_id"], name: "index_mx_hosts_on_certificate_id", using: :btree

  create_table "raw_certificates", force: :cascade do |t|
    t.binary "sha1_fingerprint", null: false
    t.binary "raw",              null: false
  end

  add_foreign_key "certificates", "raw_certificates", column: "id"
  add_foreign_key "mx_hosts", "certificates"
end
