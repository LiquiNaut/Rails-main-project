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

ActiveRecord::Schema[7.0].define(version: 2023_04_29_094109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bank_details", force: :cascade do |t|
    t.string "bank_name"
    t.string "iban"
    t.string "swift"
    t.string "var_symbol"
    t.string "konst_symbol"
    t.bigint "invoice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_bank_details_on_invoice_id"
  end

  create_table "entities", force: :cascade do |t|
    t.string "entity_name"
    t.string "entity_type"
    t.string "first_name"
    t.string "last_name"
    t.string "street"
    t.string "street_note"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.string "ico"
    t.string "dic"
    t.string "ic_dph"
    t.bigint "invoice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_entities_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_name"
    t.string "invoice_number"
    t.date "issue_date"
    t.date "shipping_date"
    t.date "due_date"
    t.string "vehicle_information"
    t.boolean "self_issued_invoice"
    t.boolean "tax_liability_shift"
    t.string "tax_adjustment_type"
    t.string "product_type"
    t.integer "product_quantity"
    t.decimal "unit_price_without_tax", precision: 10, scale: 2
    t.decimal "total_price_without_tax", precision: 10, scale: 2
    t.decimal "vat_rate_percentage", precision: 4, scale: 2
    t.decimal "total_tax_amount_eur", precision: 10, scale: 2
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bank_details", "invoices"
  add_foreign_key "entities", "invoices"
  add_foreign_key "invoices", "users"
end
