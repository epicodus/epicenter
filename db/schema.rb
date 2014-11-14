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

ActiveRecord::Schema.define(version: 20141114181118) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assessments", force: true do |t|
    t.string   "title"
    t.string   "section"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cohort_id"
    t.integer  "number"
  end

  create_table "attendance_records", force: true do |t|
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tardy"
  end

  add_index "attendance_records", ["created_at"], name: "index_attendance_records_on_created_at", using: :btree
  add_index "attendance_records", ["student_id"], name: "index_attendance_records_on_student_id", using: :btree
  add_index "attendance_records", ["tardy"], name: "index_attendance_records_on_tardy", using: :btree

  create_table "cohorts", force: true do |t|
    t.string   "description"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: true do |t|
    t.integer  "requirement_id"
    t.string   "comment"
    t.integer  "score_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "review_id"
  end

  create_table "old_bank_accounts", force: true do |t|
    t.string   "account_uri"
    t.string   "verification_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "student_id"
    t.boolean  "verified"
    t.string   "last_four_string"
  end

  add_index "old_bank_accounts", ["student_id"], name: "index_old_bank_accounts_on_student_id", using: :btree
  add_index "old_bank_accounts", ["verified"], name: "index_old_bank_accounts_on_verified", using: :btree

  create_table "old_credit_cards", force: true do |t|
    t.string   "credit_card_uri"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "last_four_string"
  end

  add_index "old_credit_cards", ["student_id"], name: "index_old_credit_cards_on_student_id", using: :btree

  create_table "payment_methods", force: true do |t|
    t.string   "account_uri"
    t.string   "verification_uri"
    t.integer  "student_id"
    t.boolean  "verified"
    t.string   "last_four_string"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: true do |t|
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payment_uri"
    t.integer  "student_id"
    t.integer  "old_payment_method_id"
    t.string   "old_payment_method_type"
    t.integer  "fee",                     default: 0, null: false
    t.integer  "payment_method_id"
  end

  add_index "payments", ["old_payment_method_type", "old_payment_method_id"], name: "payment_method_index", using: :btree
  add_index "payments", ["student_id"], name: "index_payments_on_student_id", using: :btree

  create_table "plans", force: true do |t|
    t.string   "name"
    t.integer  "recurring_amount"
    t.integer  "upfront_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_amount"
  end

  create_table "requirements", force: true do |t|
    t.string   "content"
    t.integer  "assessment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reviews", force: true do |t|
    t.integer  "submission_id"
    t.integer  "admin_id"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scores", force: true do |t|
    t.integer  "value"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", force: true do |t|
    t.integer  "student_id"
    t.string   "link"
    t.text     "note"
    t.integer  "assessment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "needs_review"
  end

  create_table "users", force: true do |t|
    t.string   "email",                       default: "", null: false
    t.string   "encrypted_password",          default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",               default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "plan_id"
    t.boolean  "recurring_active"
    t.integer  "cohort_id"
    t.string   "primary_payment_method_type"
    t.integer  "primary_payment_method_id"
    t.string   "type"
    t.integer  "current_cohort_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["plan_id"], name: "index_users_on_plan_id", using: :btree
  add_index "users", ["recurring_active"], name: "index_users_on_recurring_active", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
