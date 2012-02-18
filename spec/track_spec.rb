require File.join(File.dirname(__FILE__), %w[spec_helper])

require 'active_model'

class Post
  extend ActiveModel::Callbacks
  extend ActiveModel::Serialization

  define_model_callbacks :create
  attr_accessor :id, :to_param

  include Timeline::Track
  track :new_post

  def save
    run_callbacks :create
    true
  end
end

describe Timeline::Track do
  describe "included in an AR class" do
    before { @post = Post.new }

    it "tracks on create by default" do
      @post.should_receive(:track_new_post_after_create)
      @post.save
    end

    it "adds the activity to the global timeline set" do
      Timeline.redis.should_receive(:sadd).with(:global, kind_of(Hash))
      @post.save
    end
  end
end
