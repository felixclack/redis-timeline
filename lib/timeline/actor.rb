module Timeline::Actor
  extend ActiveSupport::Concern

  included do
    def timeline(options={})
      Timeline.get_list options
    end
  end
end