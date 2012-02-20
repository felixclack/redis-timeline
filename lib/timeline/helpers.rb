module Timeline
  module Helpers
    class DecodeException < StandardError; end

    def encode(object)
      ::MultiJson.encode(object)
    end

    def decode(object)
      return unless object

      begin
        ::MultiJson.decode(object)
      rescue ::MultiJson::DecodeError => e
        raise DecodeException, e
      end
    end

    def get_list(options={})
      defaults = { list_name: "global:activity", start: 0, end: 19 }
      if options.is_a? Hash
        defaults.merge!(options)
      elsif options.is_a? Symbol
        case options
        when :global
          defaults.merge!(list_name: "global:activity")
        end
      end
      Timeline.redis.lrange defaults[:list_name], defaults[:start], defaults[:end]
    end
  end
end