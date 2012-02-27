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
  attr_accessor :id, :creator_id

  include Timeline::Track

  track :new_comment, extra_fields: [:post_name, :post_id]

  def initialize(options={})
    @creator_id = options.delete :creator_id
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
  attr_accessor :id, :to_param

  def initialize(options={})
    @id = options.delete :id
  end

  class << self
    def find user_id
      User.new(id: user_id)
    end
  end
end

describe Timeline::Track do
  let(:creator) { User.new(id: 1) }
  let(:post) { Post.new(creator_id: creator.id, name: "New post") }

  describe "included in an ActiveModel-compliant class" do
    it "tracks on create by default" do
      post.should_receive(:track_new_post_after_create)
      post.save
    end

    it "uses the creator as the actor by default" do
      post.should_receive(:creator).and_return(mock("User", id: 1, to_param: "1", followers: []))
      post.save
    end

    it "adds the activity to the global timeline set" do
      post.save
      creator.timeline(:global).last.should be_kind_of(Timeline::Activity)
    end

    it "adds the activity to the actor's timeline" do
      post.save
      creator.timeline.last.should be_kind_of(Timeline::Activity)
    end

    it "cc's the actor's followers by default" do
      follower = User.new(id: 2)
      User.any_instance.should_receive(:followers).and_return([follower])
      post.save
      follower.timeline.last.verb.should == "new_post"
      follower.timeline.last.actor.id.should == 1
    end
  end

  describe "with extra_fields" do
    let(:comment) { Comment.new(creator_id: creator.id, id: 1) }

    it "stores the extra fields in the timeline" do
      comment.save
      creator.timeline.first.should respond_to :post_id
    end
  end
end
