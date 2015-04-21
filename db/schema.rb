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

ActiveRecord::Schema.define(version: 20150416181301) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendance_records", force: :cascade do |t|
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tardy"
    t.date     "date"
  end

  add_index "attendance_records", ["created_at"], name: "index_attendance_records_on_created_at", using: :btree
  add_index "attendance_records", ["student_id"], name: "index_attendance_records_on_student_id", using: :btree
  add_index "attendance_records", ["tardy"], name: "index_attendance_records_on_tardy", using: :btree

  create_table "code_reviews", force: :cascade do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cohort_id"
    t.integer  "number"
  end

  create_table "cohorts", force: :cascade do |t|
    t.string   "description"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cohorts", ["start_date"], name: "index_cohorts_on_start_date", using: :btree

  create_table "companies", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "website"
    t.string   "address"
    t.string   "contact_name"
    t.string   "contact_phone"
    t.string   "contact_email"
    t.string   "contact_title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: :cascade do |t|
    t.integer  "objective_id"
    t.integer  "score_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "review_id"
  end

  create_table "internships", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "cohort_id"
    t.text     "description"
    t.text     "ideal_intern"
    t.boolean  "clearance_required"
    t.text     "clearance_description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "objectives", force: :cascade do |t|
    t.string   "content"
    t.integer  "code_review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string   "account_uri"
    t.string   "verification_uri"
    t.integer  "student_id"
    t.boolean  "verified"
    t.string   "last_four_string"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payment_uri"
    t.integer  "student_id"
    t.integer  "fee",               default: 0, null: false
    t.integer  "payment_method_id"
    t.string   "status"
  end

  add_index "payments", ["student_id"], name: "index_payments_on_student_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.string   "name"
    t.integer  "recurring_amount"
    t.integer  "upfront_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_amount"
  end

  create_table "ratings", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "internship_id"
    t.string   "interest"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer  "submission_id"
    t.integer  "admin_id"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scores", force: :cascade do |t|
    t.integer  "value"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "student_id"
    t.string   "link"
    t.integer  "code_review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "needs_review"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                     default: "", null: false
    t.string   "encrypted_password",        default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             default: 0,  null: false
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
    t.integer  "primary_payment_method_id"
    t.string   "type"
    t.integer  "current_cohort_id"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",         default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["plan_id"], name: "index_users_on_plan_id", using: :btree
  add_index "users", ["recurring_active"], name: "index_users_on_recurring_active", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
