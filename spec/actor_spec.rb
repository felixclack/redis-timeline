require File.join(File.dirname(__FILE__), %w[spec_helper])

class User
  include Timeline::Actor

  attr_accessor :id
end

describe Timeline::Actor do
  describe "when included" do
    before { @user = User.new }

    it "defines a timeline association" do
      expect(@user).to respond_to :timeline
    end

    describe ".timeline" do
      subject { @user.timeline }

      it { should == [] }
    end
  end
end