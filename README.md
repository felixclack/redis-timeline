redis-timeline
===========

Redis backed timelines in your app.

Features
--------

* store your timeline in Redis.

Examples
--------

The simple way...

    class Post < ActiveRecord::Base
      include Timeline::Track

      track :new_post

    end

By default, track fires in the `after_create` callback of your model and uses `self` as the object and `creator` as the actor.

You can specify these options explicity...

    class Comment < ActiveRecord::Base
      include Timeline::Track
      belongs_to :author, class_name: "User"
      belongs_to :post

      track :new_comment,
        on: :update,
        actor: :author,
        target: :post,
        object: [:body]
        followers: :post_participants

      delegate :participants, to: :post, prefix: true
    end

Parameters
----------

`track` accepts the following parameters...

the first param is the verb name.

The rest all fit neatly in an options hash.

* `on:` [ActiveModel callback]
  You use it to specify whether you want the timeline activity created after a create, update or destroy.
  Default: :create

* `actor:` [the method that specifies the object that took this action]
  In the above example, comment.author is this object.
  Default: :creator, so make sure this exists if you don't specify a method here

* `object:` defaults to self, which is good most of the time.
  You can override it if you need to

* `target:` [related to the `:object` method above. In the example this is the post related to the comment]
  default: nil

* `followers:` [who should see this story in their timeline. This references a method on the actor]
  Defaults to the method `followers` defined by Timeline::Actor.

* `extra_fields:` [accepts an array of method names that you would like to cache the value of in your timeline]
  Defaults to nil.

* `if:` symbol or proc/lambda lets you put conditions on when to track.

Display a timeline
------------------

To retrieve a timeline for a user...

    class User < ActiveRecord::Base
      include Timeline::Actor
    end

The timeline objects are just hashes that are extended by [Hashie](http://github.com/intridea/hashie) to provide method access to the keys.

    user = User.find(1)
    user.timeline # => [<Timeline::Activity verb='new_comment' ...>]

Requirements
------------

* redis
* active_support
* hashie

Install
-------

Install redis.

Add to your Gemfile:

    gem 'redis-timeline'

Or install it by hand:

    gem install redis-timeline

Setup your redis instance. For a Rails app, something like this...

    # in config/initializers/redis.rb

    Timeline.redis = "localhost:6379/timeline"

Author
------

Original author: Felix Clack

License
-------

(The MIT License)

Copyright (c) 2012 Felix Clack

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
