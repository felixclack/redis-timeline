require File.join(File.dirname(__FILE__), %w[spec_helper])

require 'active_model'

class Post
  extend ActiveModel::Callbacks

  define_model_callbacks :create
  attr_accessor :id, :to_param, :creator_id, :name

  include Timeline::Track
  track :new_post

  def initialize(options={})
    @creator_id = options.delete :creator_id
    @name = options.delete :name
  end

  def save
    run_callbacks :create
    true
  end

  def creator
    User.find(creator_id)
  end

  def to_s
    name
  end
end

class Comment
  extend ActiveModel::Callbacks

  define_model_callbacks :create
  attr_accessor :id, :creator_id, :body

  include Timeline::Track

  track :new_comment, object: [:post_name, :post_id, :body], mentionable: :body

  def initialize(options={})
    @creator_id = options.delete :creator_id
    @body = options.delete :body
  end

  def save
    run_callbacks :create
    true
  end

  def post_id
    1
  end

  def post_name
    "My Post"
  end

  def creator
    User.find(creator_id)
  end

  def to_s
    "Comment"
  end
end

class User
  include Timeline::Actor
  attr_accessor :id, :to_param, :username

  def initialize(options={})
    @id = options.delete :id
    @username = options.delete :username
  end

  class << self
    def find user_id
      User.new(id: user_id)
    end

    def find_by_username username
      User.new(username: username)
    end
  end
end

describe Timeline::Track do
  let(:creator) { User.new(id: 1, username: "first_user") }
  let(:post) { Post.new(creator_id: creator.id, name: "New post") }
  let(:comment) { Comment.new(creator_id: creator.id, id: 1) }

  describe "included in an ActiveModel-compliant class" do
    it "tracks on create by default" do
      expect(post).to receive(:track_new_post_after_create)
      post.save
    end

    it "uses the creator as the actor by default" do
      expect(post).to receive(:creator).and_return(double("User", id: 1, to_param: "1", followers: []))
      post.save
    end

    it "adds the activity to the global timeline set" do
      post.save
      expect(creator.timeline(:global).last).to be_kind_of(Timeline::Activity)
    end

    it "adds the activity to the actor's timeline" do
      post.save
      expect(creator.timeline.last).to be_kind_of(Timeline::Activity)
    end

    it "cc's the actor's followers by default" do
      follower = User.new(id: 2)
      expect_any_instance_of(User).to receive(:followers).and_return([follower])
      post.save
      expect(follower.timeline.last.verb).to eq("new_post")
      expect(follower.timeline.last.actor.id).to eq(1)
    end
  end

  describe "with extra_fields" do
    it "stores the extra fields in the timeline" do
      comment.save
      expect(creator.timeline.first.object).to respond_to :post_id
    end
  end

  describe "tracking mentions" do
    it "adds to a user's mentions timeline" do
      allow(User).to receive(:find_by_username).and_return(creator)
      Comment.new(creator_id: creator.id, body: "@first_user should see this").save
      expect(creator.timeline(:mentions).first.object.body).to eq("@first_user should see this")
    end
  end
end
