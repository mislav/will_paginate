require 'rspec'
require 'view_helpers/view_example_group'

Dir[File.expand_path('../matchers/*_matcher.rb', __FILE__)].each { |matcher| require matcher }

RSpec.configure do |config|
  config.include Module.new {
    protected

    def include_phrase(string)
      PhraseMatcher.new(string)
    end

    def have_deprecation(msg)
      DeprecationMatcher.new(msg)
    end

    def run_queries(num)
      QueryCountMatcher.new(num)
    end

    def ignore_deprecation
      ActiveSupport::Deprecation.silence { yield }
    end

    def show_queries(&block)
      counter = QueryCountMatcher.new(nil)
      counter.run block
    ensure
      queries = counter.performed_queries
      if queries.any?
        puts queries
      else
        puts "no queries"
      end
    end
  }

  config.mock_with :mocha
  config.backtrace_exclusion_patterns << /view_example_group/
  config.expose_dsl_globally = false
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
end
