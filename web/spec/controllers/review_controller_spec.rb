require 'spec_helper'

describe ReviewController do

  before(:all) do
    @reviewee = User.create!(:email => "dbp@cs.brown.edu")
    @reviewer = User.create!(:email => "sk+0@cs.brown.edu")
    @resource = "b:r:foo:#{@reviewee.id}"
    @activity_id = "1234"
  end

  after(:all) do
    @reviewee.delete
    @reviewer.delete
  end

  it "should create links for reviewers" do
    res = "some-resource"
    r = Review.setup_review(@activity_id, res, @reviewer, @reviewee)
    links = ReviewController.reviewer_links(r)
    expect(links[:save]).to(eq("/review/save/#{r.id}"))
    expect(links[:lookup]).to(eq("/review/lookup/#{r.id}"))
  end

  it "should fetch non-started reviews" do
    res = "some-resource"
    r = Review.setup_review(@activity_id, res, @reviewer, @reviewee)
    
    get :lookup, :rid => r.id
    response.status.should eq 200
    response.body.should eq "null"
  end

  it "should fetch started reviews" do
    res = "some-other-resource"
    r = Review.setup_review(@activity_id, res, @reviewer, @reviewee)
    review = '{"review":"This review has contents"}'
    r.update_or_start(review)
    
    get :lookup, :rid => r.id
    response.status.should eq 200
    response.body.should eq review
  end

  it "should save new reviews" do
    controller.login_browserid @reviewer.email
    
    res = "resource-again"
    r = Review.setup_review(@activity_id, res, @reviewer, @reviewee)
    review = '{"review":"This one too!"}'

    post :save, :rid => r.id, :data => review
    response.status.should eq 200
    response.body.should eq review

    controller.logout_browserid
  end

  it "should 404 on non-reviewer saves" do
    controller.login_browserid @reviewee.email
    res = "another-resource"
    r = Review.setup_review(@activity_id, res, @reviewer, @reviewee)

    review = '{"review":"Sneaky non-reviewer submission"}'

    expect {
      post :save, :rid => r.id, :data => review
    }.to raise_error ActionController::RoutingError

    controller.logout_browserid
  end

end

