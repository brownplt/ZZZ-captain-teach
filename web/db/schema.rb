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

ActiveRecord::Schema.define(version: 20130819150212) do

  create_table "abuse_records", force: true do |t|
    t.integer  "user_id"
    t.string   "abuse_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "abuse_records", ["user_id"], name: "index_abuse_records_on_user_id"

  create_table "assignments", force: true do |t|
    t.string   "uid"
    t.integer  "path_ref_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
  end

  add_index "assignments", ["course_id"], name: "index_assignments_on_course_id"

  create_table "blobs", force: true do |t|
    t.string   "uid"
    t.string   "ref"
    t.integer  "user_id"
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blobs", ["user_id"], name: "index_blobs_on_user_id"

  create_table "courses", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "editors", force: true do |t|
    t.integer  "path_ref_id"
    t.string   "title"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "git_ref_id"
  end

  add_index "editors", ["git_ref_id"], name: "index_editors_on_git_ref_id"
  add_index "editors", ["path_ref_id"], name: "index_editors_on_path_ref_id"

  create_table "git_refs", force: true do |t|
    t.integer  "user_repo_id"
    t.string   "git_oid"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", force: true do |t|
    t.integer  "user_id"
    t.string   "message"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"

  create_table "path_refs", force: true do |t|
    t.integer  "user_repo_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "review_assignments", force: true do |t|
    t.integer  "reviewer_id"
    t.integer  "reviewee_id"
    t.string   "activity_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "resource"
  end

  add_index "review_assignments", ["activity_id"], name: "index_review_assignments_on_activity_id"
  add_index "review_assignments", ["reviewee_id"], name: "index_review_assignments_on_reviewee_id"
  add_index "review_assignments", ["reviewer_id"], name: "index_review_assignments_on_reviewer_id"

  create_table "reviews", force: true do |t|
    t.integer  "review_assignment_id"
    t.boolean  "done"
    t.integer  "path_ref_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reviews", ["path_ref_id"], name: "index_reviews_on_path_ref_id"
  add_index "reviews", ["review_assignment_id"], name: "index_reviews_on_review_assignment_id"

  create_table "students_courses", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "course_id"
  end

  create_table "submitteds", force: true do |t|
    t.integer  "user_id"
    t.string   "activity_id"
    t.string   "resource"
    t.datetime "submission_time"
    t.string   "submission_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "review_count",    default: 0
    t.string   "known"
  end

  add_index "submitteds", ["user_id"], name: "index_submitteds_on_user_id"

  create_table "teachers_courses", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "course_id"
  end

  create_table "user_repos", force: true do |t|
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.integer  "user_repo_id"
    t.boolean  "is_test"
    t.string   "role"
  end

  add_index "users", ["user_repo_id"], name: "index_users_on_user_repo_id"

end
