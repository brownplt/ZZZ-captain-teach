require 'spec_helper'
require 'nokogiri' # NOTE(dbp): may require gem install nokogiri

describe AssignmentController do
  before(:all) do
    @c = Course.create!(:title => "Foo Talkin Real Good")
    email = "dbp@talkinthefoo.org"
    @teacher = User.create!(:email => email)
    @pr = PathRef.create!(
      :user_repo => @teacher.user_repo,
      :path => "test-assignment.jrny"
    )
    @pr.create_file('
#lang scribble/base #test

@(require ct-scribble/ct-lib)

@journey{034852b4-f93e-11e2-b6ba-cf7c3de49d69}

@title{Function Definition With Review}

@function-reviewable[\'include-run "1d47760e-f93e-11e2-a40e-8f0fb1c03259"]{
  @header{foo(x):}
  @check{}
}
', "Test assignment", DEFAULT_GIT_USER)
    @a = Assignment.create!(:path_ref => @pr, :course => @c)
    @c.teachers << @teacher
    email = "dbp@not-a-foo-talker-yet.biz"
    @not_the_teacher = User.create!(:email => email)
    @c.students << @not_the_teacher
    @c.save!
  end

  after(:all) do
    @teacher.delete
    @not_the_teacher.delete
    
  end

  it "should 404 on invalid uid" do
    expect {
      get :get_assignment, :uid => "NotAValidUid"
    }.to raise_error ActionController::RoutingError
  end

  it "should 404 on non-teacher grading access" do
    controller.login_browserid @not_the_teacher.email

    expect {
      get :grade_assignment, :uid => @a.uid, :user_id => 1
    }.to raise_error ActionController::RoutingError
    controller.logout_browserid
    
  end

  it "should succeed on teacher grading access" do
    controller.login_browserid @teacher.email

    get :grade_assignment, :uid => @a.uid, :user_id => @not_the_teacher.id
    response.status.should eq 200

    controller.logout_browserid    
  end

  describe "Scribble" do
    before(:all) do
      o = Object.new
      def o.path
        scribble_file("function_with_review.jrny")
      end
      html = AssignmentController.path_to_html(@not_the_teacher, o, false, "unknown_assignment_id")
      @doc = Nokogiri::HTML(html)
    end

    it "should have a resource for saving" do
      controller.login_browserid @not_the_teacher.email
      get :get_assignment, :uid => @a.uid
      html = controller.instance_variable_get(:@html)
      doc = Nokogiri::HTML(html)
      node = doc.css("[data-resources]")[0]
      resources = JSON.parse(node["data-resources"])
      type, perm, ref, args, user = Resource::parse(resources["path"])
      type.should(eq("p"))
      perm.should(eq("rw"))
      user.should(eq(@not_the_teacher))
      args.should(eq({"assignment_id" => @a.uid, "reviews" => 2}))
      controller.logout_browserid
    end

    it "should have a resource for getting reviews" do
      node = @doc.css("[data-parts]")[0]
      parts = JSON.parse(node["data-parts"])

      check_part = parts[0]
      check_part["name"].should(eq("check"))
      check_resource = Resource::parse(check_part["read_reviews"])
      check_resource[2].should(eq(AssignmentController.part_ref(node["data-activity-id"], "check")))
      check_resource[0].should(eq("inbox-for-read"))
      check_do_reviews = Resource::parse(check_part["do_reviews"])
      check_do_reviews[2].should(eq(AssignmentController.reviews_ref(
                                      AssignmentController.part_ref(
                                          node["data-activity-id"],
                                          "check"
                                        ))))

      body_part = parts[1]
      body_part["name"].should(eq("body"))
      body_read_reviews = Resource::parse(body_part["read_reviews"])
      body_read_reviews[2].should(eq(AssignmentController.part_ref(node["data-activity-id"], "body")))
      body_read_reviews[0].should(eq("inbox-for-read"))
      body_do_reviews = Resource::parse(body_part["do_reviews"])
      body_do_reviews[2].should(eq(AssignmentController.reviews_ref(
                                      AssignmentController.part_ref(
                                          node["data-activity-id"],
                                          "body"
                                        ))))

      path_resource = Resource::parse(JSON.parse(node["data-resources"])["path"])
      path_resource[3]["reviews"].should(eq(2))


    end
  end
end
