require 'spec_helper'

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
end
