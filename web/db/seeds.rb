# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


if Rails.env.development?

  FileUtils.rm_rf(USER_GIT_REPO_PATH)
  FileUtils.mkdir(USER_GIT_REPO_PATH)
  
  captain = User.create!(:email => "edward@captainteach.org")
  captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)

  course = Course.create!(:title => "CS001")
  course.teachers << captain
  course.save!

  path1 = PathRef.create!(:user_repo => captains_log, :path => "multiple-choice.jrny")
  example_assignment1 = Assignment.create!({
    :path_ref => path1,
    :course => course
  })

  path2 = PathRef.create!(:user_repo => captains_log, :path => "function.jrny")
  example_assignment2 = Assignment.create!({
    :path_ref => path2,
    :course => course
  })

  path3 = PathRef.create!(:user_repo => captains_log, :path => "oracle.jrny")
  example_assignment3 = Assignment.create!({
    :path_ref => path3,
    :course => course
  })

  path4 = PathRef.create!(:user_repo => captains_log, :path => "tutorial.jrny")
  example_assignment4 = Assignment.create!({
    :path_ref => path4,
    :course => course
  })

  path5 = PathRef.create!(:user_repo => captains_log, :path => "updater.jrny")
  example_assignment5 = Assignment.create!({
    :path_ref => path5,
    :course => course
  })

  user1 = User.create!(:email => "henry@cs.brown.edu")
  course.students << user1

  user2 = User.create!(:email => "cedric@cs.brown.edu")
  course.students << user2

  print("Visit the demo course at: #{APP_URL}/course/#{course.id}\n")

end

