require 'rspec'
require File.expand_path('../view_helpers/view_example_group', __FILE__)
begin
  require 'ruby-debug'
rescue LoadError
  # no debugger available
end

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
end

class PhraseMatcher
  def initialize(string)
    @string = string
    @pattern = /\b#{Regexp.escape string}\b/
  end

  def matches?(actual)
    @actual = actual.to_s
    @actual =~ @pattern
  end

  def failure_message
    "expected #{@actual.inspect} to contain phrase #{@string.inspect}"
  end

  def negative_failure_message
    "expected #{@actual.inspect} not to contain phrase #{@string.inspect}"
  end
end

require 'stringio'

class DeprecationMatcher
  def initialize(message)
    @message = message
  end

  def matches?(block)
    @actual = hijack_stderr(&block)
    PhraseMatcher.new("DEPRECATION WARNING: #{@message}").matches?(@actual)
  end

  def failure_message
    "expected deprecation warning #{@message.inspect}, got #{@actual.inspect}"
  end

  private

  def hijack_stderr
    err = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string.rstrip
  ensure
    $stderr = err
  end
end
