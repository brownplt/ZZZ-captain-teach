namespace :ct do
  desc "GC all user repos to avoid blowup"
  task gc_user_repos: :environment do
    UserRepo.all.each do |ur|
      spawn "/usr/bin/env git gc", [:err, :out] => "/dev/null", :chdir => ur.path
    end
  end

  # bundle exec rake ct:create_grade_dirs[8] RAILS_ENV=production
  desc "Create a directory of code for a given solution and its submissions"
  task :create_grade_dirs, [:assignment] => [:environment] do |t, args|
    puts "Args: #{args}\n"
    a = Assignment.find_by(:id => args[:assignment])
    a.course.students.each do |u|
      Grading::assignment_to_dir(u, a)
    end
  end

end

