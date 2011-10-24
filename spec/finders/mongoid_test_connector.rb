require 'mongoid'

Mongoid.database = Mongo::Connection.new.db('will_paginate_test')
