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

  path1 = PathRef.create!(:user_repo => captains_log, :path => "example.scrbl")
  example_assignment1 = Assignment.create!({
    :path_ref => path1
  })
end

