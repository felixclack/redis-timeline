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
      post.should_receive(:creator).and_return(mock("User", id: 1, to_param: "1"))
      post.save
    end

    it "adds the activity to the global timeline set" do
      post.save
      creator.timeline(:global).first.should include(post.to_s)
    end

    it "adds the activity to the actor's timeline" do
      post.save
      creator.timeline.last.should include(post.to_s)
    end
  end
end
