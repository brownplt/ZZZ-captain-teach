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

ActiveRecord::Schema.define(version: 20130617183646) do

  create_table "function_data", force: true do |t|
    t.string   "ref"
    t.integer  "user_id"
    t.string   "check_block"
    t.string   "definition"
    t.string   "header"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "function_data", ["user_id"], name: "index_function_data_on_user_id"

  create_table "git_refs", force: true do |t|
    t.integer  "repo_id"
    t.string   "hash"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "path_refs", force: true do |t|
    t.integer  "repo_id"
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
  end

end
