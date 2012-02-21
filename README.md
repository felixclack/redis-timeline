timeline
===========

Redis backed timelines in your app.

Features
--------

* store your timeline in Redis.

Examples
--------

The simple way...

    class Post < ActiveRecord::Base
      track :new_post
    end

By default, track fires in the `after_create` callback of your model and uses `self` as the object and `creator` as the actor.

You can specify these options explicity...

    class Comment < ActiveRecord::Base
      belongs_to :author, class_name: "User"
      belongs_to :post

      track :new_comment, actor: :author, target: :post
    end

Requirements
------------

* redis
* active_support

Install
-------

Install redis.

Add to your Gemfile:

    gem 'timeline'

Or install it by hand:

    gem install timeline

Setup your redis instance. For a Rails app, something like this...

    # in config/initializers/redis.rb

    Timeline.redis = "localhost:9736"

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
