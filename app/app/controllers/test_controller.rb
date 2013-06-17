require 'open3'
require 'json'

class TestController < ApplicationController

  def all_assignments
  end

  def fetch_assignments
    where_we_are = File.expand_path File.dirname(__FILE__)
    ct_lang = File.expand_path("../../../src/scribble/ct-lang-main.rkt", where_we_are)
    example_file = File.expand_path('../../../src/assignments/example.scrbl',where_we_are)
    stdin, stdout, stderr = Open3.popen3('racket', ct_lang, example_file)
    input = stdout.gets()
    parsed = JSON::parse(input)
    @output = Commands::interp_tag(1, parsed, example_file)
    render :json => [@output]
  end

end
