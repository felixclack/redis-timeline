require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Timeline do
  it("can set a redis instance") { Timeline.should respond_to(:redis=) }
  it("has a namespace, timeline") { Timeline.redis.namespace.should == "tmtest" }

  it "sets the namespace through a url-like string" do
    Timeline.redis = 'localhost:9736/namespace'
    Timeline.redis.namespace.should == 'namespace'
  end
end

