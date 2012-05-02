require File.join(File.dirname(__FILE__), %w[spec_helper])



describe Timeline::Track do
  let(:user) { User.create(username: "first_user") }
  let(:post) { Post.new(user_id: user.id, title: "New post") }
  let(:comment) { Comment.new(user_id: user.id) }

  describe "included in an ActiveModel-compliant class" do
    it "tracks on create by default" do
      post.should_receive(:track_new_post_after_create)
      post.save
    end

    it "adds the activity to the global timeline set" do
      post.save
      user.timeline(:global).last.should be_kind_of(Timeline::Activity)
    end

    it "adds the activity to the actor's timeline" do
      post.save
      user.timeline.last.should be_kind_of(Timeline::Activity)
    end

    it "cc's the actor's followers by default" do
      follower = User.create(:username => "follower one")
      User.any_instance.should_receive(:followers).and_return([follower])
      post.save
      follower.timeline.last.verb.should == "new_post"
      follower.timeline.last.actor.id.should == user.id
    end
  end

  describe "with extra_fields" do
    it "stores the extra fields in the timeline" do
      comment.save
      user.timeline.first.object.should respond_to :post_id
    end
  end

  describe "tracking mentions" do
    it "adds to a user's mentions timeline" do
      User.stub(:find_by_username).and_return(user)
      Comment.create(user_id: user.id, body: "@first_user should see this").save
      user.timeline(:mentions).first.object.body.should == "@first_user should see this"
    end
  end

  describe "tracking merge similar items" do
    it "should merged" do
      c1 = Comment.create(:user => user, :body => "Comment for merge 1")
      c2 = Comment.create(:user => user, :body => "Comment for merge 2")
      user.timeline(:posts).first.object.class.should == [].class
      user.timeline(:posts).first.object.count.should == 2
      # should not merged affect other user
      user2 = User.create(:username => "user 2")
      Comment.create(:user => user2, :body => "Comment 3")
      user.timeline(:posts).first.object.count.should == 2
      user2.timeline(:posts).first.object.class.should_not == [].class
      # should not merge with added other verbs
      c3 = Comment.create(:user => user, :body => "Comment for merge 3")
      user.timeline(:posts).first.object.count.should == 3
      p1 = Post.create(:user => user, :title => "Post 1")
      c4 = Comment.create(:user => user, :body => "Comment for not merge")
      user.timeline(:posts).first.object.class.should_not == [].class
    end
  end
end
