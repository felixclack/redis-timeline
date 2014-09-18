require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Timeline::Activity do
  describe "initialized with json" do
    let(:json) { { id: "1", verb: "new_post" } }

    it "returns a Hashie-fied object" do
      expect(Timeline::Activity.new(json).id).to eq("1")
      expect(Timeline::Activity.new(json).verb).to eq("new_post")
    end
  end
end
