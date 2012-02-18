require 'active_support'

module Timeline::Track
  extend ActiveSupport::Concern

  module ClassMethods
    def track(name, options={})
      @name = name
      @callback = options.delete :on
      @callback ||= :create
      @actor = options.delete :actor

      method_name = "track_#{@name}_after_#{@callback}".to_sym
      define_activity_method method_name

      send "after_#{@callback}".to_sym, method_name
    end

    private
      def define_activity_method(method_name)
        define_method method_name do
          actor = @actor || self
          add_activity self.activity(@name, actor)
        end
      end

  end

  protected
    def activity(name, actor)
      {
        activity_type: name,
        actor: {
          actor_id: actor.id,
          actor_subject: actor.class.to_s,
          url: actor.to_param
        }
      }
    end

    def add_activity(activity_item)
      Timeline.redis.sadd :global, activity_item
    end
end