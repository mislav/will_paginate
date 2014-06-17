require 'rspec'
require 'view_helpers/view_example_group'
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

    def run_queries(num)
      QueryCountMatcher.new(num)
    end

    def ignore_deprecation
      ActiveSupport::Deprecation.silence { yield }
    end

    def run_queries(num)
      QueryCountMatcher.new(num)
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
  config.backtrace_clean_patterns << /view_example_group/
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

class QueryCountMatcher
  def initialize(num)
    @expected_count = num
  end

  def matches?(block)
    run(block)

    if @expected_count.respond_to? :include?
      @expected_count.include? @count
    else
      @count == @expected_count
    end
  end

  def run(block)
    $query_count = 0
    $query_sql = []
    block.call
  ensure
    @queries = $query_sql.dup
    @count = $query_count
  end

  def performed_queries
    @queries
  end

  def failure_message
    "expected #{@expected_count} queries, got #{@count}\n#{@queries.join("\n")}"
  end

  def negative_failure_message
    "expected query count not to be #{@expected_count}"
  end
end
