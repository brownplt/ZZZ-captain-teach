require 'open3'
require 'json'

class TestController < ApplicationController

  def all_assignments
  end

  def fetch_assignments
    parsed = JSON::parse(run_scribble("example.scrbl"))
    @output = Commands::interp_tag(1, parsed, "example.scrbl")
    render :json => [@output]
  end

  def test_assignment
  end

  def masquerade
    fake_user = User.create!
    session[:masquerade_user] = fake_user.id
    redirect_to :back
  end

  def end_masquerade
    User.find(session[:masquerade_user]).destroy
    session.delete(:masquerade_user)
    redirect_to :back
  end

  def server_tests
    ref = "foo"
    part_ref = AssignmentController.part_ref(ref, "check")
    review_ref = AssignmentController.reviews_ref(part_ref)
    u = User.create!(:email => "gfy")
    Blob.create!(:ref => ref, :user => u, :data => JSON.dump({check: "my checks are unforgable"}))
    data = [{ resource: Resource::mk_resource("b", "r", ref, {}, u.id),
              save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                 { blob_user_id: u.id, key: current_user.id },
                                                 current_user.id)}]
    Blob.create!(:ref => review_ref, :user => current_user, :data => JSON.dump(data))
    
    @data = JSON.dump({
      parts: [{
       name: "check",
       do_reviews: Resource::mk_resource("b", "r", review_ref, {}, current_user.id)
      }]
    })
  end
  
  private

  def run_scribble(name)
    where_we_are = File.expand_path File.dirname(__FILE__)
    ct_lang = File.expand_path("../../../src/scribble/ct-lang-main.rkt", where_we_are)
    file = File.expand_path('../../../src/assignments/' + name,where_we_are)
    stdin, stdout, stderr = Open3.popen3('racket', ct_lang, file)
    stdout.gets()
  end
  
end
