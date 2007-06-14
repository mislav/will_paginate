require 'test/unit'

unless defined?(ActiveRecord)
  require File.join(File.dirname(__FILE__), 'boot')
  require File.join(File.dirname(__FILE__), 'lib', 'activerecord_test_connector')
  require 'action_controller/test_process'
end

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

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

unless Hash.instance_methods.include? 'slice'
  Hash.class_eval do
    # Returns a new hash with only the given keys.
    def slice(*keys)
      allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      reject { |key,| !allowed.include?(key) }
    end

    # Replaces the hash with only the given keys.
    def slice!(*keys)
      replace(slice(*keys))
    end
  end
end

ActiveRecordTestConnector.setup
ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end
