module Timeline::Track
  extend ActiveSupport::Concern

  module ClassMethods
    def track(name, options={})
      @name = name
      @callback = options.delete :on
      @callback ||= :create
      @actor = options.delete :actor
      @subject = options.delete :subject
      @target = options.delete :target

      method_name = "track_#{@name}_after_#{@callback}".to_sym
      define_activity_method method_name

      send "after_#{@callback}".to_sym, method_name
    end

    private
      def define_activity_method(method_name)
        define_method method_name do
          actor = !@actor.nil? ? send(@actor) : creator
          object = !@object.nil? ? send(@object.to_sym) : self
          target = !@target.nil? ? send(@target.to_sym) : nil
          add_activity self.activity(verb: @name, actor: actor, object: object, target: target)
        end
      end
  end

  protected
    def activity(options={})
      {
        verb: options[:verb],
        actor: {
          id: options[:actor].id,
          class: options[:actor].class.to_s,
          url: options[:actor].to_param,
          display_name: options[:actor].to_s
        },
        object: {
          id: options[:object].id,
          class: options[:object].class.to_s,
          url: options[:object].to_param,
          display_name: options[:object].to_s
        },
        target: options_for_target(options[:target])
      }
    end

    def add_activity(activity_item)
      redis_add "global:activity", activity_item
      redis_add "user:id:#{activity_item[:actor][:actor_id]}:activity", activity_item
    end

    def redis_add(list, activity_item)
      Timeline.redis.lpush list, Timeline.encode(activity_item)
    end

    def options_for_target(target)
      if !target.nil?
        {
          id: target.id,
          class: target.class.to_s,
          url: target.to_param,
          display_name: target.to_s
        }
      else
        nil
      end
    end
end