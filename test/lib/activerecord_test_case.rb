require 'lib/activerecord_test_connector'

class ActiveRecordTestCase < Test::Unit::TestCase
  if defined?(ActiveSupport::Testing::SetupAndTeardown)
    include ActiveSupport::Testing::SetupAndTeardown
  end

  if defined?(ActiveRecord::TestFixtures)
    include ActiveRecord::TestFixtures
  end
  # Set our fixture path
  if ActiveRecordTestConnector.able_to_connect
    self.fixture_path = File.join(File.dirname(__FILE__), '..', 'fixtures')
    self.use_transactional_fixtures = true
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

  protected

    def assert_queries(num = 1)
      $query_count = 0
      yield
    ensure
      assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
    end

    def assert_no_queries(&block)
      assert_queries(0, &block)
    end
end

ActiveRecordTestConnector.setup
