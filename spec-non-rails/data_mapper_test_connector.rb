require 'sqlite3'
require 'dm-core'
require 'dm-core/support/logger'
require 'dm-migrations'

class Animal
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :notes, Text
end

class Ownership
  include DataMapper::Resource

  belongs_to :animal, :key => true
  belongs_to :human, :key => true
end

class Human
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  has n, :ownerships
  has 1, :pet, :model => 'Animal', :through => :ownerships, :via => :animal
end

if 'irb' == $0
  DataMapper.logger.set_log($stdout, :debug)
  DataMapper.logger.auto_flush = true
end
