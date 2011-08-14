require 'rspec'
require File.expand_path('../view_helpers/view_example_group', __FILE__)
begin
  require 'ruby-debug'
rescue LoadError
  # no debugger available
end

module MyExtras
  protected
  
  def include_phrase(string)
    PhraseMatcher.new(string)
  end

  def collection(params = {})
    if params[:total_pages]
      params[:per_page] = 1
      params[:total_entries] = params[:total_pages]
    end
    WillPaginate::Collection.new(params[:page] || 1, params[:per_page] || 30, params[:total_entries])
  end
end

RSpec.configure do |config|
  # config.include My::Pony, My::Horse, :type => :farm
  config.include MyExtras
  # config.predicate_matchers[:swim] = :can_swim?
  
  config.mock_with :mocha
end

class PhraseMatcher
  def initialize(string)
    @string = string
    @pattern = /\b#{string}\b/
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
