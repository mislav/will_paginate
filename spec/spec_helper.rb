require 'rspec'
require 'view_helpers/view_example_group'

Dir[File.expand_path('../matchers/*_matcher.rb', __FILE__)].each { |matcher| require matcher }

RSpec::Matchers.alias_matcher :include_phrase, :include

RSpec.configure do |config|
  config.include Module.new {
    protected

    def have_deprecation(msg)
      output(/^DEPRECATION WARNING: #{Regexp.escape(msg)}/).to_stderr
    end

    def ignore_deprecation
      ActiveSupport::Deprecation.silence { yield }
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
