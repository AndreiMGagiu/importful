# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_23_114217) do
  create_table "affiliates", force: :cascade do |t|
    t.integer "merchant_id", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.decimal "commissions_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "website_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "email"], name: "index_affiliates_on_merchant_id_and_email", unique: true
    t.index ["merchant_id"], name: "index_affiliates_on_merchant_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_merchants_on_slug", unique: true
  end

  add_foreign_key "affiliates", "merchants"
end
