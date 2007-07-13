require 'test/unit'
require 'rubygems'

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

dirname = File.dirname(__FILE__)
require File.join(dirname, 'boot') unless defined?(ActiveRecord)
require 'action_controller/test_process'
require File.join(dirname, 'lib', 'activerecord_test_connector')

# add plugin's main lib dir to load paths
$:.unshift(File.join(dirname, '..', 'lib')).uniq!

# Test case for inheritance
class ActiveRecordTestCase < Test::Unit::TestCase
  # Set our fixture path
  if ActiveRecordTestConnector.able_to_connect
    self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
    self.use_transactional_fixtures = false
  end

  def self.fixtures(*args)
    super if ActiveRecordTestConnector.connected
  end

  def run(*args)
    super if ActiveRecordTestConnector.connected
  end

  # Default so Test::Unit::TestCase doesn't complain
  def test_truth
  end
end

ActiveRecordTestConnector.setup
ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

ActionController::Base.perform_caching = false
