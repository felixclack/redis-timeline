module Timeline
  module Helpers
    class DecodeException < StandardError; end

    def encode(object)
      ::MultiJson.encode(object)
    end

    def decode(object)
      return unless object

      begin
        ::MultiJson.load(object)
      rescue ::MultiJson::DecodeError => e
        raise DecodeException, e
      end
    end

    def get_list(options={})
      Timeline.redis.lrange options[:list_name], options[:start], options[:end]
    end
  end
end
