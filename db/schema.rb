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

ActiveRecord::Schema[7.0].define(version: 2023_04_16_210013) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "attendance_records", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "tardy"
    t.date "date"
    t.boolean "left_early"
    t.datetime "signed_out_time", precision: nil
    t.string "station"
    t.boolean "ignore"
    t.integer "old_pair_ids", default: [], array: true
    t.index ["created_at"], name: "index_attendance_records_on_created_at"
    t.index ["student_id"], name: "index_attendance_records_on_student_id"
    t.index ["tardy"], name: "index_attendance_records_on_tardy"
  end

  create_table "class_times", force: :cascade do |t|
    t.integer "wday"
    t.string "start_time"
    t.string "end_time"
  end

  create_table "class_times_courses", id: false, force: :cascade do |t|
    t.bigint "class_time_id"
    t.bigint "course_id"
    t.index ["class_time_id"], name: "index_class_times_courses_on_class_time_id"
    t.index ["course_id"], name: "index_class_times_courses_on_course_id"
  end

  create_table "code_reviews", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "course_id"
    t.integer "number"
    t.boolean "submissions_not_required"
    t.text "content"
    t.string "survey"
    t.string "github_path"
    t.datetime "visible_date", precision: nil
    t.datetime "due_date", precision: nil
    t.boolean "journal"
  end

  create_table "cohorts", id: :serial, force: :cascade do |t|
    t.string "description"
    t.date "start_date"
    t.date "end_date"
    t.integer "office_id"
    t.integer "track_id"
    t.integer "admin_id"
    t.index ["office_id"], name: "index_cohorts_on_office_id"
    t.index ["track_id"], name: "index_cohorts_on_track_id"
  end

  create_table "cohorts_courses", id: :serial, force: :cascade do |t|
    t.integer "cohort_id"
    t.integer "course_id"
  end

  create_table "course_internships", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.integer "internship_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "description", limit: 255
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "class_days"
    t.integer "admin_id"
    t.boolean "internship_course"
    t.boolean "active"
    t.integer "office_id"
    t.boolean "rankings_visible"
    t.boolean "parttime", default: false
    t.integer "language_id"
    t.integer "track_id"
    t.boolean "full"
    t.boolean "internship_assignments_visible"
    t.string "layout_file_path"
    t.bigint "cohort_id"
    t.index ["cohort_id"], name: "index_courses_on_cohort_id"
    t.index ["start_date"], name: "index_courses_on_start_date"
    t.index ["track_id"], name: "index_courses_on_track_id"
  end

  create_table "daily_submissions", force: :cascade do |t|
    t.bigint "student_id"
    t.string "link"
    t.date "date"
    t.index ["student_id"], name: "index_daily_submissions_on_student_id"
  end

  create_table "enrollments", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.integer "student_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_enrollments_on_deleted_at"
  end

  create_table "grades", id: :serial, force: :cascade do |t|
    t.integer "objective_id"
    t.integer "score_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "review_id"
  end

  create_table "internship_assignments", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.integer "internship_id"
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "internship_tracks", id: :serial, force: :cascade do |t|
    t.integer "internship_id"
    t.integer "track_id"
  end

  create_table "internships", id: :serial, force: :cascade do |t|
    t.integer "company_id"
    t.integer "old_course_id"
    t.text "description"
    t.text "ideal_intern"
    t.boolean "clearance_required"
    t.text "clearance_description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "name"
    t.string "website"
    t.string "address"
    t.integer "number_of_students"
    t.string "interview_location"
    t.string "location"
    t.string "hiring"
    t.text "mentor_name"
    t.text "mentor_years"
    t.text "work_schedule"
    t.text "projects"
    t.text "contract"
  end

  create_table "interview_assignments", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.integer "internship_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "ranking_from_company"
    t.text "feedback_from_company"
    t.integer "course_id"
    t.integer "ranking_from_student"
    t.text "feedback_from_student"
  end

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "level"
    t.boolean "archived"
  end

  create_table "languages_tracks", id: false, force: :cascade do |t|
    t.integer "track_id", null: false
    t.integer "language_id", null: false
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.string "content"
    t.integer "submission_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type"
    t.index ["submission_id"], name: "index_notes_on_submission_id"
  end

  create_table "objectives", id: :serial, force: :cascade do |t|
    t.string "content"
    t.integer "code_review_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "number"
  end

  create_table "offices", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "time_zone"
    t.string "short_name"
  end

  create_table "pair_feedback", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "pair_id"
    t.integer "q1_response"
    t.integer "q2_response"
    t.integer "q3_response"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["pair_id"], name: "index_pair_feedback_on_pair_id"
    t.index ["student_id"], name: "index_pair_feedback_on_student_id"
  end

  create_table "pairings", force: :cascade do |t|
    t.bigint "attendance_record_id"
    t.bigint "pair_id"
    t.index ["attendance_record_id"], name: "index_pairings_on_attendance_record_id"
    t.index ["pair_id"], name: "index_pairings_on_pair_id"
  end

  create_table "payment_methods", id: :serial, force: :cascade do |t|
    t.string "account_uri", limit: 255
    t.string "verification_uri", limit: 255
    t.integer "student_id"
    t.boolean "verified"
    t.string "last_four_string", limit: 255
    t.string "type", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "stripe_id"
  end

  create_table "payments", id: :serial, force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "payment_uri", limit: 255
    t.integer "student_id"
    t.integer "fee", default: 0, null: false
    t.integer "payment_method_id"
    t.string "status", limit: 255
    t.string "stripe_transaction"
    t.integer "refund_amount"
    t.boolean "offline"
    t.text "notes"
    t.string "description"
    t.boolean "refund_issued"
    t.boolean "failure_notice_sent"
    t.string "category"
    t.date "refund_date"
    t.string "refund_notes"
    t.string "qbo_journal_entry_ids", default: [], array: true
    t.bigint "cohort_id"
    t.bigint "linked_payment_id"
    t.index ["cohort_id"], name: "index_payments_on_cohort_id"
    t.index ["linked_payment_id"], name: "index_payments_on_linked_payment_id"
    t.index ["student_id"], name: "index_payments_on_student_id"
  end

  create_table "peer_evaluations", force: :cascade do |t|
    t.bigint "evaluator_id"
    t.bigint "evaluatee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["evaluatee_id"], name: "index_peer_evaluations_on_evaluatee_id"
    t.index ["evaluator_id"], name: "index_peer_evaluations_on_evaluator_id"
  end

  create_table "peer_questions", force: :cascade do |t|
    t.string "content"
    t.string "category"
    t.integer "number"
  end

  create_table "peer_responses", force: :cascade do |t|
    t.bigint "peer_evaluation_id"
    t.bigint "peer_question_id"
    t.string "response"
    t.index ["peer_evaluation_id"], name: "index_peer_responses_on_peer_evaluation_id"
    t.index ["peer_question_id"], name: "index_peer_responses_on_peer_question_id"
  end

  create_table "plans", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "upfront_amount"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "close_io_description"
    t.boolean "archived"
    t.boolean "loan"
    t.boolean "standard"
    t.boolean "parttime"
    t.boolean "upfront"
    t.string "short_name"
    t.integer "order"
    t.integer "student_portion"
    t.boolean "isa"
  end

  create_table "ratings", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.integer "internship_id"
    t.string "interest"
    t.text "notes"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "number"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.integer "submission_id"
    t.integer "admin_id"
    t.text "note"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "student_signature"
  end

  create_table "scores", id: :serial, force: :cascade do |t|
    t.integer "value"
    t.string "description", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "signatures", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.string "signature_id"
    t.string "type"
    t.boolean "is_complete"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "signature_request_id"
  end

  create_table "submissions", id: :serial, force: :cascade do |t|
    t.integer "student_id"
    t.text "link"
    t.integer "code_review_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "needs_review"
    t.integer "times_submitted"
    t.string "review_status"
    t.integer "admin_id"
    t.text "journal"
    t.boolean "exempt"
    t.index ["code_review_id"], name: "index_submissions_on_code_review_id"
    t.index ["student_id"], name: "index_submissions_on_student_id"
  end

  create_table "tracks", id: :serial, force: :cascade do |t|
    t.string "description"
    t.boolean "archived"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: ""
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "name", limit: 255
    t.integer "plan_id"
    t.integer "old_course_id"
    t.integer "primary_payment_method_id"
    t.string "type", limit: 255
    t.integer "current_course_id"
    t.string "invitation_token", limit: 255
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type", limit: 255
    t.integer "invitations_count", default: 0
    t.string "stripe_customer_id"
    t.string "github_uid"
    t.boolean "referral_email_sent"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.boolean "demographics"
    t.integer "attendance_warnings_sent"
    t.integer "solo_warnings_sent"
    t.integer "starting_cohort_id"
    t.boolean "teacher"
    t.integer "cohort_id"
    t.boolean "probation_teacher"
    t.integer "parttime_cohort_id"
    t.boolean "probation_advisor"
    t.integer "probation_teacher_count"
    t.integer "probation_advisor_count"
    t.string "legal_name"
    t.integer "upfront_amount"
    t.text "staff_sticky"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_secret"
    t.string "pronouns"
    t.integer "checkins", default: 0
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["parttime_cohort_id"], name: "index_users_on_parttime_cohort_id"
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "cohorts", "offices"
  add_foreign_key "cohorts", "tracks"
  add_foreign_key "courses", "cohorts"
  add_foreign_key "courses", "tracks"
  add_foreign_key "daily_submissions", "users", column: "student_id"
  add_foreign_key "notes", "submissions"
  add_foreign_key "pair_feedback", "users", column: "pair_id"
  add_foreign_key "pair_feedback", "users", column: "student_id"
  add_foreign_key "pairings", "users", column: "pair_id"
  add_foreign_key "payments", "cohorts"
  add_foreign_key "payments", "payments", column: "linked_payment_id"
  add_foreign_key "peer_evaluations", "users", column: "evaluatee_id"
  add_foreign_key "peer_evaluations", "users", column: "evaluator_id"
end
