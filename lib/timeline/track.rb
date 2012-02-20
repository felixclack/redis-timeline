module Timeline::Track
  extend ActiveSupport::Concern

  module ClassMethods
    def track(name, options={})
      @name = name
      @callback = options.delete :on
      @callback ||= :create
      @actor = options.delete :actor
      @subject = options.delete :subject

      method_name = "track_#{@name}_after_#{@callback}".to_sym
      define_activity_method method_name

      send "after_#{@callback}".to_sym, method_name
    end

    private
      def define_activity_method(method_name)
        define_method method_name do
          actor = !@actor.nil? ? send(@actor) : creator
          subject = !@subject.nil? ? send(@subject.to_sym) : self
          add_activity self.activity(@name, actor, subject)
        end
      end
  end

  protected
    def activity(name, actor, subject)
      {
        activity_type: name,
        actor: {
          actor_id: actor.id,
          actor_class: actor.class.to_s,
          url: actor.to_param,
          title: actor.to_s
        },
        subject: {
          subject_id: subject.id,
          subject_class: subject.class.to_s,
          url: subject.to_param,
          title: subject.to_s
        }
      }
    end

    def add_activity(activity_item)
      redis_add "global:activity", activity_item
      redis_add "user:id:#{activity_item[:actor][:actor_id]}:activity", activity_item
    end

    def redis_add(list, activity_item)
      Timeline.redis.lpush list, Timeline.encode(activity_item)
    end
end