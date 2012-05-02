require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Timeline::Activity do
  describe "initialized with json" do
    let(:json) { MultiJson.dump({ id: "1", verb: "new_post"}) }

    it "returns a Hashie-fied object" do
      Timeline::Activity.new(json).id.should == "1"
      Timeline::Activity.new(json).verb.should == "new_post"
    end
  end
end