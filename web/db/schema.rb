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

ActiveRecord::Schema.define(version: 20130703152059) do

  create_table "assignments", force: true do |t|
    t.string   "uid"
    t.integer  "path_ref_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blobs", force: true do |t|
    t.string   "uid"
    t.string   "ref"
    t.integer  "user_id"
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blobs", ["user_id"], name: "index_blobs_on_user_id"

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

  create_table "path_refs", force: true do |t|
    t.integer  "user_repo_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  add_index "users", ["user_repo_id"], name: "index_users_on_user_repo_id"

end
