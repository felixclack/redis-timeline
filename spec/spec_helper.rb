require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib redis-timeline]))
dir = File.dirname(File.expand_path(__FILE__))

require 'active_record'
require 'rails'

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')


class Post < ActiveRecord::Base
  include Timeline::Track
  track :new_post, :actor => :user

  belongs_to :user
  has_many :comments

  def to_s
    self.title
  end
end

class Comment < ActiveRecord::Base
  include Timeline::Track

  track :new_comment, :actor => :user, object: [:post_title, :post_id, :body], mentionable: :body, :merge_similar => true

  belongs_to :post
  belongs_to :user

  def post_title
    self.post.title if !self.post.blank?
  end

  def to_s
    self.body
  end
end

class User < ActiveRecord::Base
  include Timeline::Actor

  has_many :posts
  has_many :comments

  def to_s
    self.username
  end
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :posts do |t|
    t.column :title, :string
    t.column :body, :text
    t.column :user_id, :integer
  end

  create_table :users do |t|
    t.column :username, :string
  end

  create_table :comments do |t|
    t.column :post_id, :integer
    t.column :user_id, :integer
    t.column :body, :text
  end
end

Timeline.redis = '127.0.0.1:6379/tmtest'

RSpec.configure do |config|
  config.after :suite do
    keys = Timeline.redis.keys("*")
    Timeline.redis.del(*keys)
  end
end
