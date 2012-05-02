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
      @mentionable = options.delete :mentionable

      method_name = "track_#{@name}_after_#{@callback}".to_sym
      define_activity_method method_name, actor: @actor, 
                                          object: @object, 
                                          target: @target, 
                                          followers: @followers, 
                                          verb: name, 
                                          merge_similar: options[:merge_similar],
                                          mentionable: @mentionable

      send "after_#{@callback}".to_sym, method_name, if: options.delete(:if)
    end

    private
      def define_activity_method(method_name, options={})
        define_method method_name do
          @actor = send(options[:actor])
          @fields_for = {}
          @object = set_object(options[:object])
          @target = !options[:target].nil? ? send(options[:target].to_sym) : nil
          @extra_fields ||= nil
          @merge_similar = options[:merge_similar] == true ? true : false
          @followers = @actor.send(options[:followers].to_sym)
          @mentionable = options[:mentionable]
          add_activity(activity(verb: options[:verb]))
        end
      end
  end

  protected
    def activity(options={})
      {
        cache_key: "#{options[:verb]}_u#{@actor.id}_#{Time.now.to_i}",
        verb: options[:verb],
        actor: options_for(@actor),
        object: options_for(@object),
        target: options_for(@target),
        created_at: Time.now
      }
    end

    def add_activity(activity_item)
      redis_store_item(activity_item)
      add_activity_by_global(activity_item)
      add_activity_to_user(activity_item[:actor][:id], activity_item)
      add_activity_by_user(activity_item[:actor][:id], activity_item)
      add_mentions(activity_item)
      add_activity_to_followers(activity_item) if @followers.any?
    end

    def add_activity_by_global(activity_item)
      redis_add "global:activity", activity_item
    end

    def add_activity_by_user(user_id, activity_item)
      redis_add "user:id:#{user_id}:posts", activity_item
    end

    def add_activity_to_user(user_id, activity_item)
      redis_add "user:id:#{user_id}:activity", activity_item
    end

    def add_activity_to_followers(activity_item)
      @followers.each { |follower| add_activity_to_user(follower.id, activity_item) }
    end

    def add_mentions(activity_item)
      return unless @mentionable and @object.send(@mentionable)
      @object.send(@mentionable).scan(/@\w+/).each do |mention|
        if user = @actor.class.find_by_username(mention[1..-1])
          add_mention_to_user(user.id, activity_item)
        end
      end
    end

    def add_mention_to_user(user_id, activity_item)
      redis_add "user:id:#{user_id}:mentions", activity_item
    end

    def extra_fields_for(object)
      return {} unless @fields_for.has_key?(object.class.to_s.downcase.to_sym)
      @fields_for[object.class.to_s.downcase.to_sym].inject({}) do |sum, method|
        sum[method.to_sym] = @object.send(method.to_sym)
        sum
      end
    end

    def options_for(target)
      if !target.nil?
        {
          id: target.id,
          class: target.class.to_s,
          display_name: target.to_s
        }.merge(extra_fields_for(target))
      else
        nil
      end
    end

    def redis_add(list, activity_item)
      Timeline.redis.lpush list, activity_item[:cache_key]
    end

    def redis_store_item(activity_item)
      if @merge_similar
        # Merge similar item with last
        last_item_text = Timeline.get_list(:list_name => "user:id:#{activity_item[:actor][:id]}:posts", :start => 0, :end => 1).first
        if last_item_text
          last_item = Timeline::Activity.new Timeline.decode(last_item_text)
          if last_item[:verb].to_s == activity_item[:verb].to_s and last_item[:target] == activity_item[:target]
            activity_item[:object] = [last_item[:object], activity_item[:object]].flatten.uniq
          end
        end
      end
      Timeline.redis.set activity_item[:cache_key], Timeline.encode(activity_item)
    end

    def set_object(object)
      case
      when object.is_a?(Symbol)
        send(object)
      when object.is_a?(Array)
        @fields_for[self.class.to_s.downcase.to_sym] = object
        self
      else
        self
      end
    end

end