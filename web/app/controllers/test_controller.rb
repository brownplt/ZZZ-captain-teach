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
    u = User.find_by(id: session[:masquerade_user])
    if u.nil?
    else
      u.destroy
    end
    session.delete(:masquerade_user)
    redirect_to :back
  end

  def server_tests
    ref = "foo"
    part_ref = AssignmentController.part_ref(ref, "check")
    review_ref = AssignmentController.reviews_ref(part_ref)
    part_ref_foo = AssignmentController.part_ref(ref, "foo")
    review_ref_foo = AssignmentController.reviews_ref(part_ref_foo)
    user_index = params[:user] || User.count
    reviewee_email_a = "test_reviewee_a#{user_index}"
    reviewee_email_b = "test_reviewee_b#{user_index}"
    maybe_u_curr = User.find_by(:email => "test_reviewer#{user_index}")
    maybe_u = User.find_by(:email => reviewee_email_a)
    maybe_u2 = User.find_by(:email => reviewee_email_b)
    if maybe_u_curr.nil? and maybe_u.nil? and maybe_u2.nil?
      u_curr = User.create!(:email => "test_reviewer#{user_index}")
      u = User.create!(:email => reviewee_email_a)
      u.user_repo.create_file(ref, JSON.dump({
              status: { step: "check", reviewing: true },
              parts: {
                check: "\nmy checks are unforgable",
                foo: "\n"
              }
            }), "Init", DEFAULT_GIT_USER
      )
      u2 = User.create!(:email => reviewee_email_b)
      u2.user_repo.create_file(ref, JSON.dump({
              status: { step: "check", reviewing: true },
              parts: {
                check: "\nmy checks have already been forged",
                foo: "\n"
              }
            }), "Init", DEFAULT_GIT_USER
         )
      data = [{ resource: Resource::mk_resource("p", "r", ref, {}, u.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u.id, key: u_curr.id },
                                                   u_curr.id)},
              { resource: Resource::mk_resource("p", "r", ref, {}, u2.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u2.id, key: u_curr.id },
                                                   u_curr.id)}]
      Blob.create!(:ref => review_ref, :user => u_curr, :data => JSON.dump(data))

      u_curr.user_repo.create_file(ref, JSON.dump({
          status: { step: "check", reviewing: true },
          parts: {
            check: "\n1 is 4",
            foo: "\n"
          }
        }), "Init", DEFAULT_GIT_USER
      )

      data2 = [{ resource: Resource::mk_resource("p", "r", ref, {}, u_curr.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u_curr.id, key: u.id },
                                                   u.id)},
              { resource: Resource::mk_resource("p", "r", ref, {}, u2.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u2.id, key: u.id },
                                                   u.id)}]
      Blob.create!(:ref => review_ref, :user => u, :data => JSON.dump(data2))

    else
      u_curr = maybe_u_curr
      u = maybe_u
    end
    code_delimiters = [ {type: "code", value: "fun foo():"},
                        {type: "code", value: "\ncheck:"},
                        {type: "code", value: "\nend"} ]
    parts = [ {type: "body", value: "foo"},
              {type: "fun-checks", value: "check"} ]
    @data = JSON.dump({
      user_index: user_index,
      user1: {
          args: {
              name: "FooThing",
              codeDelimiters: code_delimiters,
              parts: parts
            },
          resources: {
              path: Resource::mk_resource("p", "rw", ref, {reviews: 2}, u_curr.id),
              steps: [{
                  name: "check",
                  type: "fun-checks",
                  read_reviews: Resource::mk_resource("inbox-for-read", "r", part_ref, {}, u_curr.id),
                  do_reviews: Resource::mk_resource("b", "r", review_ref, {}, u_curr.id)
                }, {
                  name: "foo",
                  type: "body",
                  read_reviews: Resource::mk_resource("inbox-for-read", "r", part_ref_foo, {}, u_curr.id),
                  do_reviews: Resource::mk_resource("b", "r", review_ref_foo, {}, u_curr.id)
                }]
            }
        },
      user2: {
          args: {
              name: "FooThing",
              codeDelimiters: code_delimiters,
              parts: parts
            },
          resources: {
              path: Resource::mk_resource("p", "rw", ref, {reviews: 2}, u.id),
              steps: [{
                  name: "check",
                  type: "fun-checks",
                  read_reviews: Resource::mk_resource("inbox-for-read", "r", part_ref, {}, u.id),
                  do_reviews: Resource::mk_resource("b", "r", review_ref, {}, u.id)
                }, {
                  name: "foo",
                  type: "body",
                  read_reviews: Resource::mk_resource("inbox-for-read", "r", part_ref_foo, {}, u.id),
                  do_reviews: Resource::mk_resource("b", "r", review_ref_foo, {}, u.id)
                }]
            }
      }
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
