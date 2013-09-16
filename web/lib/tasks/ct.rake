namespace :ct do
  desc "GC all user repos to avoid blowup"
  task gc_user_repos: :environment do
    UserRepo.all.each do |ur|
      spawn "/usr/bin/env git gc", [:err, :out] => "/dev/null", :chdir => ur.path
    end
  end

end
