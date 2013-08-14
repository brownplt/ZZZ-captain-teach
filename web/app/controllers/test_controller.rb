require 'open3'
require 'json'

class TestController < ApplicationController

  def all_assignments
    captains_log = UserRepo.find_by(:path => ASSIGNMENTS_PATH)
    if captains_log.nil?
      captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)
    end
    @assignments = []
    Dir.foreach(ASSIGNMENTS_PATH) do |filename|
      if filename.ends_with? ".jrny"
        existing = Assignment.includes(:path_ref).where("path_refs.path" => filename)
        if existing.length > 0
          @assignments << existing[0]
        else
          path = PathRef.create!(:user_repo => captains_log,
                                 :path => filename)
          assignment = Assignment.create!(:path_ref => path)
          @assignments << assignment
        end
      end
    end
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
      def payload(from_user, for_user, part_ref)
        { feedback: Resource::mk_resource(
              'inbox-for-write',
              'rw',
              AssignmentController.feedback_ref(part_ref),
              {
                blob_user_id: for_user,
                key: from_user,
              },
              from_user
            )
          }
      end
      data = [{ resource: Resource::mk_resource("p", "r", ref, {}, u.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u.id, key: u_curr.id,
                                                     payload: payload(u.id, u_curr.id, part_ref)},
                                                   u_curr.id)},
              { resource: Resource::mk_resource("p", "r", ref, {}, u2.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u2.id, key: u_curr.id,
                                                     payload: payload(u2.id, u_curr.id, part_ref)},
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
                                                   { blob_user_id: u_curr.id, key: u.id,
                                                     payload: payload(u_curr.id, u.id, part_ref)},
                                                   u.id)},
              { resource: Resource::mk_resource("p", "r", ref, {}, u2.id),
                save_review: Resource::mk_resource("inbox-for-write", "rw", part_ref,
                                                   { blob_user_id: u2.id, key: u.id,
                                                     payload: payload(u2.id, u.id, part_ref)},
                                                   u.id)}]
      Blob.create!(:ref => review_ref, :user => u, :data => JSON.dump(data2))

    else
      u_curr = maybe_u_curr
      u = maybe_u
    end
    code_delimiters = [ {type: "code", value: "fun foo():"},
                        {type: "code", value: "\nwhere:"},
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

  require 'nokogiri'
  def submit_tests
    o = Object.new
    def o.path
      File.expand_path("sample-assignment.jrny", ASSIGNMENTS_PATH)
    end

    def lookup(resource)
      type, perm, ref, args, user = Resource::parse(resource)
      Resource::lookup(type, perm, ref, args, user).data
    end

    def save(resource, data)
      type, perm, ref, args, user = Resource::parse(resource)
      Resource::save(type, perm, ref, args, user, JSON.dump(data))
    end

    def submit(resource, data)
      type, perm, ref, args, user = Resource::parse(resource)
      Resource::submit(type, perm, ref, args, user, JSON.dump(data), resource)
    end

    def versions(resource)
      type, perm, ref, args, user = Resource::parse(resource)
      Resource::versions(type, perm, ref, args, user, resource).data
    end

    user1 = User.find_by(:email => "henry@cs.brown.edu")
    user2 = User.find_by(:email => "cedric@cs.brown.edu")

    henryData = AssignmentController.path_to_json(user1, o)
    cedricData = AssignmentController.path_to_json(user2, o)

    henryPath = henryData[1][:resources]["path"]
    save(henryPath, {
      status: { step: "append-checks", reviewing: true },
      parts: {
        "append-checks" => "\nappend([1], [2]) is [1,2]\n",
        "append-body" => "\n",
        "Quicksort2" => "\n",
        "quick-sort-checks" => "\n",
        "quick-sort-body" => "\n",
        "Quicksort1" => "\n"
      }
    })
    submit(henryPath, {step_type: "append-checks"})

    cedricPath = cedricData[1][:resources]["path"]
    save(cedricPath, {
      status: { step: "append-checks", reviewing: true },
      parts: {
        "append-checks" => "\nappend([1], [1, 3]) is [1,3]",
        "append-body" => "\n",
        "Quicksort2" => "\n",
        "quick-sort-checks" => "\n",
        "quick-sort-body" => "\n",
        "Quicksort1" => "\n"
      }
    })
    submit(cedricPath, {step_type: "append-checks"})

    cedricDoReviews = cedricData[1][:parts][0]["do_reviews"]
    result = JSON.parse(lookup(cedricDoReviews))
    save(result[0]["save_review"], {
      resource: versions(cedricPath)[0][:resource],
      review: {
        done: true,
        correctnessComments: "Nice work",
        correctness: 1,
        designComments: "Bad design",
        design: -1
      }
    })

    henryReadReviews = henryData[1][:parts][0]["read_reviews"]
    result = lookup(henryReadReviews)
    save(result[0]["feedback"], {
      helpfullness: 2,
      comments: "This fixed my problem, thanks!"
    })

    henryResources = henryData[1][:resources]
    henryResources["steps"] = henryData[1][:parts]

    cedricResources = cedricData[1][:resources]
    cedricResources["steps"] = cedricData[1][:parts]

    @data = JSON.dump({
      user_index: "N/A",
      user1: {
        resources: henryResources,
        args: henryData[1][:args]
      },
      user2: {
        resources: cedricResources,
        args: cedricData[1][:args]
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
