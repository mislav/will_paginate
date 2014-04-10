require 'rspec'
require 'view_helpers/view_example_group'
begin
  require 'ruby-debug'
rescue LoadError
  # no debugger available
end

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
  }
  
  config.mock_with :mocha
  config.backtrace_clean_patterns << /view_example_group/
end
