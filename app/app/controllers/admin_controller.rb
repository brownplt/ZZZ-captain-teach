require 'open3'
require 'json'

class AdminController < ApplicationController

  def all_assignments
  end

  def fetch_assignments
    stdin, stdout, stderr = Open3.popen3('racket', '/home/joe/src/captain-teach/src/assignments/example.scrbl')
    parsed = JSON::parse(stdout.gets(nil))
    @output = Commands::interp_tag(1, parsed)
    render :json => [@output]
  end

end
