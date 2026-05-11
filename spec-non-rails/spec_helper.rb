require 'rspec'

RSpec.configure do |config|
  config.mock_with :mocha
  config.expose_dsl_globally = false
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
end
