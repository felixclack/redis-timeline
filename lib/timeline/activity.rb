module Timeline
  class Activity
    # include Hashie::Extensions::MethodAccess

    def initialize(options={})
      Timeline.decode options
    end
  end
end