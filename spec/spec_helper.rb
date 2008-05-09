require 'rubygems'
gem 'rspec', '~> 1.1.3'
require 'spec'

Spec::Runner.configure do |config|
  # config.include My::Pony, My::Horse, :type => :farm
  # config.predicate_matchers[:swim] = :can_swim?
  
  config.mock_with :mocha
end
