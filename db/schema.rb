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

ActiveRecord::Schema.define(version: 20160718204026) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendance_records", force: :cascade do |t|
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tardy"
    t.date     "date"
    t.boolean  "left_early"
    t.datetime "signed_out_time"
    t.integer  "pair_id"
  end

  add_index "attendance_records", ["created_at"], name: "index_attendance_records_on_created_at", using: :btree
  add_index "attendance_records", ["student_id"], name: "index_attendance_records_on_student_id", using: :btree
  add_index "attendance_records", ["tardy"], name: "index_attendance_records_on_tardy", using: :btree

  create_table "code_reviews", force: :cascade do |t|
    t.string   "title",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "number"
    t.boolean  "submissions_not_required"
  end

  create_table "course_internships", force: :cascade do |t|
    t.integer "course_id"
    t.integer "internship_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string   "description",       limit: 255
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "class_days"
    t.string   "start_time"
    t.string   "end_time"
    t.integer  "admin_id"
    t.boolean  "internship_course"
    t.boolean  "active"
  end

  add_index "courses", ["start_date"], name: "index_courses_on_start_date", using: :btree

  create_table "enrollments", force: :cascade do |t|
    t.integer  "course_id"
    t.integer  "student_id"
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

  create_table "internship_tracks", force: :cascade do |t|
    t.integer "internship_id"
    t.integer "track_id"
  end

  create_table "internships", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "old_course_id"
    t.text     "description"
    t.text     "ideal_intern"
    t.boolean  "clearance_required"
    t.text     "clearance_description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "website"
    t.string   "address"
    t.integer  "number_of_students"
  end

  create_table "interview_assignments", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "internship_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ranking_from_company"
    t.text     "feedback_from_company"
  end

  create_table "objectives", force: :cascade do |t|
    t.string   "content",        limit: 255
    t.integer  "code_review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string   "account_uri",      limit: 255
    t.string   "verification_uri", limit: 255
    t.integer  "student_id"
    t.boolean  "verified"
    t.string   "last_four_string", limit: 255
    t.string   "type",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stripe_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payment_uri",        limit: 255
    t.integer  "student_id"
    t.integer  "fee",                            default: 0, null: false
    t.integer  "payment_method_id"
    t.string   "status",             limit: 255
    t.string   "stripe_transaction"
    t.integer  "refund_amount"
    t.boolean  "offline"
    t.text     "notes"
  end

  add_index "payments", ["student_id"], name: "index_payments_on_student_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  "upfront_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_amount"
    t.string   "close_io_description"
    t.boolean  "archived"
    t.boolean  "loan"
    t.boolean  "standard"
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
    t.string   "student_signature"
  end

  create_table "scores", force: :cascade do |t|
    t.integer  "value"
    t.string   "description", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "signatures", force: :cascade do |t|
    t.integer  "student_id"
    t.string   "signature_request_id"
    t.string   "type"
    t.boolean  "is_complete"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "student_id"
    t.text     "link"
    t.integer  "code_review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "needs_review"
  end

  add_index "submissions", ["code_review_id"], name: "index_submissions_on_code_review_id", using: :btree
  add_index "submissions", ["student_id"], name: "index_submissions_on_student_id", using: :btree

  create_table "tracks", force: :cascade do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                     limit: 255, default: "", null: false
    t.string   "encrypted_password",        limit: 255, default: ""
    t.string   "reset_password_token",      limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",        limit: 255
    t.string   "last_sign_in_ip",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                      limit: 255
    t.integer  "plan_id"
    t.integer  "old_course_id"
    t.integer  "primary_payment_method_id"
    t.string   "type",                      limit: 255
    t.integer  "current_course_id"
    t.string   "invitation_token",          limit: 255
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type",           limit: 255
    t.integer  "invitations_count",                     default: 0
    t.string   "stripe_customer_id"
    t.string   "github_uid"
    t.text     "interview_feedback"
    t.boolean  "referral_email_sent"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["plan_id"], name: "index_users_on_plan_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
