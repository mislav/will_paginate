require 'sqlite3'
require 'dm-core'
require 'dm-core/support/logger'
require 'dm-migrations'

DataMapper.setup :default, 'sqlite3::memory:'

# Define models
class Animal
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :notes, Text
 
  def self.setup
    Animal.create(:name => 'Dog', :notes => "Man's best friend")
    Animal.create(:name => 'Cat', :notes => "Woman's best friend")
    Animal.create(:name => 'Lion', :notes => 'King of the Jungle')
  end
end

# Load fixtures
Animal.auto_migrate!
Animal.setup

if 'irb' == $0
  DataMapper.logger.set_log($stdout, :debug)
  DataMapper.logger.auto_flush = true
end
