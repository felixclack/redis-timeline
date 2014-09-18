require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Timeline do
  it("can set a redis instance") { expect(Timeline).to respond_to(:redis=) }
  it("has a namespace, timeline") { expect(Timeline.redis.namespace).to eq(:timeline) }

  it "sets the namespace through a url-like string" do
    Timeline.redis = 'localhost:9736/namespace'
    expect(Timeline.redis.namespace).to eq('namespace')
  end
end

