require 'active_model'

module Timeline
  class Activity < Hashie::Mash
    extend ActiveModel::Naming

    def to_partial_path
      "timelines/#{verb}"
    end
  end
end