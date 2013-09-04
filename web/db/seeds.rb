# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

if Rails.env.production?
  FileUtils.rm_rf(USER_GIT_REPO_PATH)
  FileUtils.mkdir(USER_GIT_REPO_PATH)

  captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)

  joe = User.create!(:email => "joe.politz@gmail.com")
  dbp = User.create!(:email => "dbp@dbpmail.net")
  course = Course.create!(:title => "Experimental Course")
  course.teachers << joe
  course.teachers << dbp

  sorting = PathRef.create!(:user_repo => captains_log, :path => "tutorial.jrny")
  sorting_assignment = Assignment.create!({
    :path_ref => sorting,
    :course => course
  })

  sorting1 = PathRef.create!(:user_repo => captains_log, :path => "tutorial-test-dont-click-here.jrny")
  sorting1_assignment = Assignment.create!({
    :path_ref => sorting1,
    :course => course
  })
end

if Rails.env.test?

  FileUtils.rm_rf(USER_GIT_REPO_PATH)
  FileUtils.mkdir(USER_GIT_REPO_PATH)

  captain = User.create!(:email => "edward@captainteach.org", :role => "admin")
  mates_log = UserRepo.create!(:path => REPOSITORY_PATH)
  course = Course.create!(:title => "TEST")
  course.teachers << captain

  path1 = PathRef.create!(:user_repo => mates_log, :path => "tests/scribble/assignments/simple.jrny")
  example_assignment1 = Assignment.create!({
    :path_ref => path1,
    :course => course,
    :release => DateTime::now
  })


  user1 = User.create!(:email => "henry@cs.brown.edu")
  course.students << user1

  user2 = User.create!(:email => "cedric@cs.brown.edu")
  course.students << user2

end

if Rails.env.development?

  FileUtils.rm_rf(USER_GIT_REPO_PATH)
  FileUtils.mkdir(USER_GIT_REPO_PATH)

  captain = User.create!(:email => "edward@captainteach.org", :role => "admin")
  captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)

  course = Course.create!(:title => "CS001")
  course.teachers << captain
  course.save!

  path1 = PathRef.create!(:user_repo => captains_log, :path => "multiple-choice.jrny")
  example_assignment1 = Assignment.create!({
    :path_ref => path1,
    :course => course,
    :release => DateTime::now
  })

  path2 = PathRef.create!(:user_repo => captains_log, :path => "function.jrny")
  example_assignment2 = Assignment.create!({
    :path_ref => path2,
    :course => course,
    :release => DateTime::now
  })

  path3 = PathRef.create!(:user_repo => captains_log, :path => "oracle.jrny")
  example_assignment3 = Assignment.create!({
    :path_ref => path3,
    :course => course,
    :release => DateTime::now
  })

  path4 = PathRef.create!(:user_repo => captains_log, :path => "tutorial.jrny")
  example_assignment4 = Assignment.create!({
    :path_ref => path4,
    :course => course,
    :release => DateTime::now
  })

  path5 = PathRef.create!(:user_repo => captains_log, :path => "updater.jrny")
  example_assignment5 = Assignment.create!({
    :path_ref => path5,
    :course => course,
    :release => DateTime::now
  })

  path6 = PathRef.create!(:user_repo => captains_log, :path => "sortacle.jrny")
  example_assignment6 = Assignment.create!({
    :path_ref => path6,
    :course => course,
    :release => DateTime::now
  })

  path7 = PathRef.create!(:user_repo => captains_log, :path => "sorting.jrny")
  example_assignment7 = Assignment.create!({
    :path_ref => path7,
    :course => course,
    :release => DateTime::now
  })

  path8 = PathRef.create!(:user_repo => captains_log, :path => "sample-assignment.jrny")
  example_assignment8 = Assignment.create!({
    :path_ref => path8,
    :course => course,
    :release => DateTime::now
  })
  
  path9 = PathRef.create!(:user_repo => captains_log, :path => "reference.jrny")
  example_assignment9 = Assignment.create!({
    :path_ref => path9,
    :course => course,
    :release => DateTime::now
  })

  pathlol = PathRef.create!(:user_repo => captains_log, :path => "pre-course-survey.jrny")
  example_assignmentlol = Assignment.create!({
    :path_ref => pathlol,
    :course => course,
    :release => DateTime::now
  })


  user1 = User.create!(:email => "henry@cs.brown.edu")
  course.students << user1

  user2 = User.create!(:email => "cedric@cs.brown.edu")
  course.students << user2

  user3 = User.create!(:email => "benedict@perdue.edu")
  course.students << user3

  
  APP_URL = "http://localhost:3000"
  print("Visit the demo course at: #{APP_URL}/course/#{course.id}\n") end
