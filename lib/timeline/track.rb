module Timeline::Track
  extend ActiveSupport::Concern

  module ClassMethods
    def track(name, options={})
      @name = name
      @callback = options.delete :on
      @callback ||= :create
      @actor = options.delete :actor
      @actor ||= :creator
      @object = options.delete :object
      @target = options.delete :target
      @followers = options.delete :followers
      @followers ||= :followers
      @extra_fields = options.delete :extra_fields

      method_name = "track_#{@name}_after_#{@callback}".to_sym
      define_activity_method method_name, actor: @actor, object: @object, target: @target, followers: @followers, verb: name, extra_fields: @extra_fields

      send "after_#{@callback}".to_sym, method_name, if: options.delete(:if)
    end

    private
      def define_activity_method(method_name, options={})
        define_method method_name do
          actor = send(options[:actor])
          object = !options[:object].nil? ? send(options[:object].to_sym) : self
          target = !options[:target].nil? ? send(options[:target].to_sym) : nil
          followers = actor.send(options[:followers].to_sym)
          add_activity activity(verb: options[:verb], actor: actor, object: object, target: target, extra_fields: options[:extra_fields]), followers
        end
      end
  end

  protected
    def activity(options={})
      {
        verb: options[:verb],
        actor: options_for(options[:actor]),
        object: options_for(options[:object]),
        target: options_for(options[:target]),
        created_at: Time.now
      }.merge(add_extra_fields(options[:extra_fields]))
    end

    def add_activity(activity_item, followers)
      redis_add "global:activity", activity_item
      add_activity_to_user(activity_item, activity_item[:actor][:id])
      add_activity_to_user_post(activity_item, activity_item[:actor][:id])
      add_activity_to_followers(activity_item, followers) if followers.any?
    end

    def add_activity_to_user(activity_item, user_id)
      redis_add "user:id:#{user_id}:activity", activity_item
    end

    def add_activity_to_user_post(activity_item, user_id)
      redis_add "user:id:#{user_id}:posts", activity_item
    end

    def add_activity_to_followers(activity_item, followers)
      followers.each { |follower| add_activity_to_user(activity_item, follower.id) }
    end

    def add_extra_fields(extra_fields)
      if extra_fields.any?
        extra_fields.inject({}) do |sum, value|
          sum[value.to_sym] = send value.to_sym
        end
      else
        {}
      end
    end

    def redis_add(list, activity_item)
      Timeline.redis.lpush list, Timeline.encode(activity_item)
    end

    def options_for(target)
      if !target.nil?
        {
          id: target.id,
          class: target.class.to_s,
          display_name: target.to_s
        }
      else
        nil
      end
    end
end