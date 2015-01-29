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

  create_table "domains", force: :cascade do |t|
    t.string "name",                  null: false
    t.text   "mx_hosts", default: [],              array: true
  end

  add_index "domains", ["mx_hosts"], name: "index_domains_on_mx_hosts", using: :btree
  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree

  create_table "mx_hosts", force: :cascade do |t|
    t.string "hostname", null: false
    t.inet   "address",  null: false
  end

  add_index "mx_hosts", ["address", "hostname"], name: "index_mx_hosts_on_address_and_hostname", unique: true, using: :btree

end
