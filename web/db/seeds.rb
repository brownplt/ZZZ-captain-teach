# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


if Rails.env.development?
  captain = User.create!()
  puts ASSIGNMENTS_PATH
  captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)

  path1 = PathRef.create!(:user_repo => captains_log, :path => "multiple-choice.jrny")
  example_assignment1 = Assignment.create!({
    :path_ref => path1
  })

  path2 = PathRef.create!(:user_repo => captains_log, :path => "function.jrny")
  example_assignment2 = Assignment.create!({
    :path_ref => path2
  })

  path3 = PathRef.create!(:user_repo => captains_log, :path => "oracle.jrny")
  example_assignment3 = Assignment.create!({
    :path_ref => path3
  })
end

