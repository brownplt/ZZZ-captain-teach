require 'spec_helper'

describe Review do

  before(:all) do
    @reviewee = User.create!(:email => "dbp@cs.brown.edu")
    @reviewer = User.create!(:email => "sk@cs.brown.edu")
    @resource = "b:r:foo:#{@reviewee.id}"
    @activity_id = "1234"
    @resource_2 = "b:r:resource_2:#{@reviewee.id}"
    @resource_3 = "b:r:resource_3:#{@reviewee.id}"
    @resource_4 = "b:r:resource_4:#{@reviewee.id}"
  end

  after(:all) do
    @reviewee.delete
    @reviewer.delete
  end

  it "should setup reviews" do
    r = Review.setup_review(@activity_id, @resource, @reviewer, @reviewee)
    expect(r.review_assignment.reviewer).to(eq(@reviewer))
    expect(r.review_assignment.reviewee).to(eq(@reviewee))
    expect(r.review_assignment.activity_id).to(eq(@activity_id))
    expect(r.review_assignment.resource).to(eq(@resource))

    expect(r.done).to(eq(false))

    expect(r.path_ref.user_repo).to(eq(@reviewer.user_repo), "should be reviewer's user_repo")
    expect(r.path_ref.file_exists?).to(eq(false))
    expect(r.path_ref.path).to(eq("reviews/1234/b:r:foo:#{@reviewee.id}/#{@reviewee.id}/#{r.review_assignment.id}"))
  end

  it "should add a review" do
    r = Review.setup_review(@activity_id, @resource_2, @reviewer, @reviewee)
    expect(r.path_ref.file_exists?).to(eq(false))
    r.update_or_start("This work is a little sad")
    expect(r.path_ref.file_exists?).to(eq(true))
    expect(r.path_ref.contents).to(eq("This work is a little sad"))
  end

  it "should update a review" do
    r = Review.setup_review(@activity_id, @resource_3, @reviewer, @reviewee)
    expect(r.path_ref.file_exists?).to(eq(false))
    r.update_or_start("This work is a little sad")
    expect(r.path_ref.file_exists?).to(eq(true))
    expect(r.path_ref.contents).to(eq("This work is a little sad"))
    r.update_or_start("Actually, not bad")
    expect(r.path_ref.contents).to(eq("Actually, not bad"))
  end

  it "should know if it has started" do
    r = Review.setup_review(@activity_id, "some-resource", @reviewer, @reviewee)
    expect(r.started?).to(eq(false))
    r.update_or_start("Some reviewing content")
    expect(r.started?).to(eq(true))
  end

  it "should get the latest" do
    r = Review.setup_review(@activity_id, "another-resource", @reviewer, @reviewee)
    expect(r.contents).to(eq("null"))
    r.update_or_start("Some reviewing content")
    expect(r.contents).to(eq("Some reviewing content"))
  end

end

