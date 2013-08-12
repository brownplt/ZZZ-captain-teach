require 'spec_helper'

describe ResourceController do
  before(:all) do
    @user = User.create!(email: "edward@captainteach.org")
    @b = Blob.new(:ref => "foo", :user => @user, :data => "{}")
    @b.save!()

    @file = "blah"
    @user.user_repo.create_file("foo", @file,
                                "message", DEFAULT_GIT_USER)
  end

  describe "Blobs" do

    it "GET lookup with r, rw, or rc should succeed" do
      get :lookup,
        :resource => Resource::mk_resource("b","r","foo",{},@user.id),
        :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)

      get :lookup,
        :resource => Resource::mk_resource("b","rw","foo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)

      get :lookup, :resource => Resource::mk_resource("b","rc","foo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)
    end

    it "GET on unknown ref or user should fail" do
      get :lookup, :resource => Resource::mk_resource("b","rw","bazfoo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(404))

      get :lookup, :resource => Resource::mk_resource("b","rw","bazfoo",{},"not-an-id"), :format => :json
      response.response_code.should(eq(404))

    end

    it "POST with rw should succeed" do
      post :save, :resource => Resource::mk_resource("b","rw","foo",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      resp = JSON::parse(response.body)
      resp["success"].should(be_true)
      @b.reload()
      d = JSON::parse(@b.data)
      d.should(be_a(Array))
      d[0].should(eq(1))
    end

    it "POST with rc when the item exists should fail" do
      post :save, :resource => Resource::mk_resource("b","rc","foo",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with r should fail" do
      post :save, :resource => Resource::mk_resource("b","r","foo",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with rc or rw with new resource should succeed" do
      post :save, :resource => Resource::mk_resource("b","rc","bar1",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      Blob.find_by(user: @user, ref: "bar1").should(be_a(Blob))

      post :save, :resource => Resource::mk_resource("b","rw","bar2",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      Blob.find_by(user: @user, ref: "bar2").should(be_a(Blob))
    end

    it "POST with r should fail" do
      post :save, :resource => Resource::mk_resource("b","r","bar1",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "GET versions should succeed for existing blob" do
      resource = Resource::mk_resource("b","r","foo",{},"#{@user.id}")

      get :versions, :resource => resource, :format => :json
      response.response_code.should(eq(200))
      v = JSON::parse(response.body)
      v.should(be_a(Array))
      v.should(eq([{"time"=>"", "resource"=>resource}]))
    end

    it "GET versions should 404 on non-existent blob" do
      get :versions, :resource => Resource::mk_resource("b","rw","bar3",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(404))
    end
  end

  describe "PathRef" do
    it "GET with r, rc, or rw should succeed" do
      get :lookup, :resource => Resource::mk_resource("p","r","foo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))

      get :lookup, :resource => Resource::mk_resource("p","rw","foo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))

      get :lookup, :resource => Resource::mk_resource("p","rc","foo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))
    end

    it "GET on unknown ref or user should fail" do
      get :lookup, :resource => Resource::mk_resource("p","rw","bazfoo",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(404))

      get :lookup, :resource => Resource::mk_resource("p","rw","foo",{},"not-an-id"), :format => :json
      response.response_code.should(eq(404))
    end

    it "POST with rw should succeed" do
      @user.user_repo.create_file("foo1", @file,
                                "message", DEFAULT_GIT_USER)

      path_ref = PathRef.new(:user_repo => @user.user_repo, :path => "foo1")
      before_versions = path_ref.versions.length
      new_data = "My New File"
      post :save, :resource => Resource::mk_resource("p","rw","foo1",{},"#{@user.id}"), :data => new_data,
      :format => :json
      response.response_code.should(eq(200))
      resp = JSON::parse(response.body)
      resp["success"].should(be_true)

      path_ref.contents.should(eq(new_data))
      path_ref.versions.length.should(eq(before_versions + 1))
    end

    it "POST with rc when the item exists should fail" do
      post :save, :resource => Resource::mk_resource("p","rc","foo",{},"#{@user.id}"), :data => "Blah blah blah",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with r should fail" do
      post :save, :resource => Resource::mk_resource("p","r","foo",{},"#{@user.id}"), :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with rc or rw with new resource should succeed" do
      data = "My Program"
      post :save, :resource => Resource::mk_resource("p","rc","bar1",{},"#{@user.id}"), :data => data,
      :format => :json
      response.response_code.should(eq(200))
      @user.user_repo.lookup_file_head("bar1").should(eq(data))

      data2 = "My Program 2"
      post :save, :resource => Resource::mk_resource("p","rw","bar2",{},"#{@user.id}"), :data => data2,
      :format => :json
      response.response_code.should(eq(200))
      @user.user_repo.lookup_file_head("bar2").should(eq(data2))
    end

    it "POST with r should fail" do
      post :save, :resource => Resource::mk_resource("p","r","bar3",{},"#{@user.id}"), :data => "Baz",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "GET versions should succeed for existing pathref" do
      resource = Resource::mk_resource("p","r","foo",{},"#{@user.id}")

      get :versions, :resource => resource, :format => :json
      response.response_code.should(eq(200))
      v = JSON::parse(response.body)
      v.should(be_a(Array))
    end

    it "GET versions should 404 on non-existent pathref" do
      get :versions, :resource => Resource::mk_resource("p","rw","bar3",{},"#{@user.id}"), :format => :json
      response.response_code.should(eq(404))
    end

    it "GET versions should return all versions of pathref" do
      post :save, :resource => Resource::mk_resource("p","rw","bar4",{},"#{@user.id}"), :data => "Program 1",
      :format => :json
      post :save, :resource => Resource::mk_resource("p","rw","bar4",{},"#{@user.id}"), :data => "Program 2",
      :format => :json
      post :save, :resource => Resource::mk_resource("p","rw","bar4",{},"#{@user.id}"), :data => "Program 3",
      :format => :json

      get :versions, :resource => Resource::mk_resource("p","rw","bar4",{},"#{@user.id}"), :format => :json
      resp = JSON::parse(response.body)
      resp.should(be_a(Array))
      resp.length.should(eq(3))
    end

    it "GET versions should return gitrefs to old versions of the pathref" do
      data1 = "Program 1"
      post :save, :resource => Resource::mk_resource("p","rw","bar5",{},"#{@user.id}"), :data => data1,
      :format => :json
      data2 = "Program 2"
      post :save, :resource => Resource::mk_resource("p","rw","bar5",{},"#{@user.id}"), :data => data2,
      :format => :json

      get :versions, :resource => Resource::mk_resource("p","rw","bar5",{},"#{@user.id}"), :format => :json
      resp = JSON::parse(response.body)
      resp.should(be_a(Array))
      resp.length.should(eq(2))

      get :lookup, :resource => resp[0]["resource"], :format => :json
      resp1 = JSON::parse(response.body)
      resp1["file"].should(eq(data2))

      get :lookup, :resource => resp[1]["resource"], :format => :json
      resp1 = JSON::parse(response.body)
      resp1["file"].should(eq(data1))
    end
  end

  it "should create read-only references from other references" do
    resource = Resource::mk_resource("p","rw","to-be-read-only",{},"#{@user.id}")
    post :save, :resource => resource, :data => "some allowed stuff", :format => :json
    response.response_code.should(eq(200))

    read_only = Resource::read_only(resource)

    post :save, :resource => read_only, :data => "some stuff", :format => :json
    response.response_code.should(eq(405))

  end

  describe "Inboxes" do
    before(:each) do
      Blob.destroy_all
    end
    it "should allow writing by key, and create on write" do
      ref = "some-id-for-activity/reviews"
      Blob.count.should(eq(0))
      resource = Resource::mk_resource("inbox-for-write", "rw", ref, { blob_user_id: @user.id, key: "1" }, @user.id)
      data = JSON.dump({"review" => "My review, or whatever"})
      post :save, :resource => resource, :data => data, :format => :json
      response.response_code.should(eq(200))

      Blob.count.should(eq(1))

      get :lookup, :resource => resource

      response.response_code.should(eq(200))
      response.body.should(eq(data))
    end

    it "should always echo the most recent version" do
      ref = "some-id-for-activity/reviews"
      b = Blob.create!(:user => @user, :ref => ref, :data => "{}")
      resource = Resource::mk_resource("inbox-for-write", "rw", ref, { blob_user_id: @user.id, key: "1" }, @user.id)
      data = JSON.dump({"review" => "My review, or whatever"})
      post :save, :resource => resource, :data => data, :format => :json
      response.response_code.should(eq(200))

      data2 = JSON.dump({"review" => "My review, after some reflection"})
      post :save, :resource => resource, :data => data2, :format => :json
      response.response_code.should(eq(200))

      get :lookup, :resource => resource

      response.response_code.should(eq(200))
      response.body.should(eq(data2))
    end

    it "should allow a reader to see all the versions" do
      ref = "some-id-for-activity/reviews"
      blob_for_inbox = Blob.create!(:user => @user, :ref => ref, :data => "{}")
      resource = Resource::mk_resource(
          "inbox-for-read",
          "r",
          ref,
          {},
          @user.id
        )
      write_resource1 = Resource::mk_resource(
          "inbox-for-write",
          "rw",
          ref,
          { blob_user_id: @user.id, key: "42" },
          @user.id)
      write_resource2 = Resource::mk_resource(
          "inbox-for-write",
          "rw",
          ref,
          { blob_user_id: @user.id, key: "84" },
          @user.id)

      data = JSON.dump({"review" => "First review"})
      post :save, :resource => write_resource1, :data => data, :format => :json
      response.response_code.should(eq(200), "First review write")

      data2 = JSON.dump({"review" => "Second review"})
      post :save, :resource => write_resource2, :data => data2, :format => :json
      response.response_code.should(eq(200), "Second attempt")

      get :lookup, :resource => resource

      response.response_code.should(eq(200))

      resp = JSON::parse(response.body)
      resp[0].should(eq(JSON.parse(data)))
      resp[1].should(eq(JSON.parse(data2)))
    end

    it "should incorporate payload into written data" do
      ref = "some-activity-for-payload/reviews"
      resource = Resource::mk_resource(
          "inbox-for-read",
          "r",
          ref,
          {},
          @user.id
        )
      feedback1 = "this will be a feedback link someday"
      write_resource1 = Resource::mk_resource(
          "inbox-for-write",
          "rw",
          ref,
          { blob_user_id: @user.id,
            key: "42",
            payload: { feedback: feedback1 }
          },
          @user.id)
      feedback2 = "this will be a feedback link NOW"
      write_resource2 = Resource::mk_resource(
          "inbox-for-write",
          "rw",
          ref,
          { blob_user_id: @user.id,
            key: "84",
            payload: { feedback: feedback2}
          },
          @user.id)

      data = JSON.dump({"review" => "First review"})
      post :save, :resource => write_resource1, :data => data, :format => :json
      response.response_code.should(eq(200), "First review write")

      data2 = JSON.dump({"review" => "Second review"})
      post :save, :resource => write_resource2, :data => data2, :format => :json
      response.response_code.should(eq(200), "Second attempt")

      get :lookup, :resource => resource

      response.response_code.should(eq(200))

      resp = JSON::parse(response.body)
      after_data1 = JSON.parse(data)
      after_data1["feedback"] = feedback1
      after_data2 = JSON.parse(data2)
      after_data2["feedback"] = feedback2
      resp[0].should(eq(after_data1))
      resp[1].should(eq(after_data2))

    end

  end

  describe "Submitted" do
    def create_sub(id)
      u = User.find_by(:id => id)
      if u.nil?
        User.create!(:id => id)
      end
      Submitted.create!(
        :submission_type => "check",
        :activity_id => @activity_id,
        :resource => Resource::mk_resource('b', 'r', @activity_id, {}, id),
        :user_id => id,
        :submission_time => Time.zone.now
      )
    end

    before(:each) do
      Submitted.destroy_all
      Blob.destroy_all
      @activity_id = 'some-activity-id'
    end

    it "should allow submission, and put submissions in the Submitted table" do
      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, {}, @user.id)

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "done" }),
        :format => :json
      response.response_code.should(eq(200))

      s = Submitted.last
      s.resource.should(eq(resource_to_submit))
      s.user_id.should(eq(@user.id))
      s.submission_type.should(eq("done"))
      s.activity_id.should(eq(@activity_id))
    end

    it "should allow submission, and set up reviews" do
      part_ref = AssignmentController.part_ref(@activity_id, "check")

      create_sub(102)
      create_sub(89)
      create_sub(35)
      create_sub(23)

      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, { reviews: 3 }, @user.id)

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "check" }),
        :format => :json
      response.response_code.should(eq(200))

      review_ref = AssignmentController.reviews_ref(part_ref)

      review_blob = Blob.find_by(:user => @user, :ref => review_ref)
      data = JSON.parse(review_blob.data)

      data.length.should(eq(3))

      r1 = Resource::parse(data[0]["save_review"])
      r2 = Resource::parse(data[1]["save_review"])
      r3 = Resource::parse(data[2]["save_review"])


      def check_feedback(uid, feedback, part_ref)
        type, perm, ref, args, user = Resource::parse(feedback)
        type.should(eq('inbox-for-write'))
        perm.should(eq('rw'))
        ref.should(eq(AssignmentController.feedback_ref(part_ref)))
        args["key"].should(eq(uid))
        user.id.should(eq(uid))
      end
      r1[0].should(eq("inbox-for-write"))
      r1[2].should(eq(part_ref))
      r1[3]["blob_user_id"].should(eq(102))
      check_feedback(102, r1[3]["payload"]["feedback"], part_ref)
      r1[4].should(eq(@user))

      print "Done with user 1\n"

      r2[0].should(eq("inbox-for-write"))
      r2[2].should(eq(part_ref))
      r2[3]["blob_user_id"].should(eq(89))
      check_feedback(89, r2[3]["payload"]["feedback"], part_ref)
      r2[4].should(eq(@user))

      print "Done with user 2\n"

      r3[0].should(eq("inbox-for-write"))
      r3[2].should(eq(part_ref))
      r3[3]["blob_user_id"].should(eq(35))
      check_feedback(35, r3[3]["payload"]["feedback"], part_ref)
      r3[4].should(eq(@user))

    end

    it "should assign reviews to a second user submitting" do
      @second_user = User.create!
      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, { reviews: 3 }, @user.id)

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "check2" }),
        :format => :json

      b2 = Blob.create!(:user => @second_user, :ref => @activity_id, :data => "{}")
      second_resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, { reviews: 3 },
                              @second_user.id)

      post :submit,
        :resource => second_resource_to_submit,
        :data => JSON.dump({ step_type: "check2" }),
        :format => :json

      part_ref = AssignmentController.part_ref(@activity_id, "check2")
      review_ref = AssignmentController.reviews_ref(part_ref)

      puts review_ref

      review_blob = Blob.find_by(:user => @second_user, :ref => review_ref)
      data = JSON.parse(review_blob.data)

      data.length.should(eq(1))
    end

    it "should only assign reviews once" do
      part_ref = AssignmentController.part_ref(@activity_id, "check")

      create_sub(52)
      create_sub(88)
      create_sub(34)
      create_sub(22)

      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, { reviews: 3 }, @user.id)

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "check" }),
        :format => :json
      response.response_code.should(eq(200))

      review_ref = AssignmentController.reviews_ref(part_ref)
      review_blob = Blob.find_by(:user => @user, :ref => review_ref)
      data = JSON.parse(review_blob.data)
      data.length.should(eq(3))
      Blob.count.should(eq(2))

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "check" }),
        :format => :json
      response.response_code.should(eq(200))

      Blob.count.should(eq(2))

      def assert_review_count(u, n)
        Submitted.find_by(
          :activity_id => @activity_id,
          :submission_type => "check",
          :user_id => u
        ).review_count.should(eq(n))
      end
      assert_review_count(52, 1)
      assert_review_count(88, 1)
      assert_review_count(34, 1)
      assert_review_count(22, 0)
      assert_review_count(@user.id, 0)

    end


    it "should allow multiple submissions" do
      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource::mk_resource('b', 'r', @activity_id, {}, @user.id)

      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "done" }),
        :format => :json
      response.response_code.should(eq(200))
      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "done again" }),
        :format => :json
      response.response_code.should(eq(200))

      s1 = Submitted.first
      s2 = Submitted.last
      s1.resource.should(eq(resource_to_submit))
      s1.user_id.should(eq(@user.id))
      s1.submission_type.should(eq("done"))
      s1.activity_id.should(eq(@activity_id))

      s2.resource.should(eq(resource_to_submit))
      s2.user_id.should(eq(@user.id))
      s2.submission_type.should(eq("done again"))
      s2.activity_id.should(eq(@activity_id))

      (s2.submission_time > s1.submission_time).should(eq(true))
    end

    it "should change submissions to read-only" do
      b = Blob.create!(:user => @user, :ref => @activity_id, :data => "{}")
      resource_to_submit =
        Resource.mk_resource('b', 'rw', @activity_id, {}, @user.id)
      post :submit,
        :resource => resource_to_submit,
        :data => JSON.dump({ step_type: "done" }),
        :format => :json
      response.response_code.should(eq(200))
      s = Submitted.first
      s.resource.should(eq(Resource::read_only(resource_to_submit)))
      s.user_id.should(eq(@user.id))
    end
  end

end
