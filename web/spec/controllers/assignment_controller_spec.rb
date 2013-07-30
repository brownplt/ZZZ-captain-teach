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
    @pr.create_file("#lang scribble/base\n", "Test assignment", DEFAULT_GIT_USER)
    @a = Assignment.create!(:path_ref => @pr, :course => @c)
    @c.teachers << @teacher
    email = "dbp@not-a-foo-talker-yet.biz"
    @not_the_teacher = User.create!(:email => email)
    @c.students << @not_the_teacher
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
    it "should have a resource for getting reviews" do
      o = Object.new
      def o.path
        scribble_file("function_with_review.jrny")
      end
      html = controller.path_to_html(@not_the_teacher,o)
      doc = Nokogiri::HTML(html)
      node = doc.css("[data-parts]")[0]
      parts = JSON.parse(node["data-parts"])

      check_part = parts[0]
      check_part["name"].should(eq("check"))
      check_resource = Resource::parse(check_part["resource"])
      check_resource[2].should(eq(controller.part_ref(node["data-activity-id"], "check")))
      check_resource[0].should(eq("inbox-for-read"))

      body_part = parts[1]
      body_part["name"].should(eq("body"))
      body_resource = Resource::parse(body_part["resource"])
      body_resource[2].should(eq(controller.part_ref(node["data-activity-id"], "body")))
      body_resource[0].should(eq("inbox-for-read"))
    end
  end
end
