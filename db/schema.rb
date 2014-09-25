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

ActiveRecord::Schema.define(version: 20140925230630) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assessments", force: true do |t|
    t.string   "title"
    t.string   "section"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "section_number"
  end

  create_table "bank_accounts", force: true do |t|
    t.string   "account_uri"
    t.string   "verification_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "verified"
    t.boolean  "active"
  end

  create_table "grades", force: true do |t|
    t.integer  "submission_id"
    t.integer  "requirement_id"
    t.string   "comment"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: true do |t|
    t.integer  "amount"
    t.string   "method"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bank_account_id"
    t.string   "payment_uri"
  end

  create_table "requirements", force: true do |t|
    t.string   "content"
    t.integer  "assessment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", force: true do |t|
    t.integer  "user_id"
    t.string   "link"
    t.text     "note"
    t.integer  "assessment_id"
    t.boolean  "graded"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "provider"
    t.string   "uid"
    t.boolean  "admin",                  default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
