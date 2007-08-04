require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class ArrayPaginationTest < ActiveRecordTestCase
  def setup
    @array = ('a'..'e').to_a
  end
  
  cases = [
    { :current => 1,  :per_page => 3,  :expected => %w( a b c ) },
    { :current => 2,  :per_page => 3,  :expected => %w( d e ) },
    { :current => 1,  :per_page => 5,  :expected => %w( a b c d e ) },
    { :current => 3,  :per_page => 5,  :expected => [] },
    { :current => -1, :per_page => 5,  :expected => [] },
    { :current => 1,  :per_page => -5, :expected => [] }
  ]
  
  cases.each_with_index do |conditions, index|
    define_method("test_case_#{index}") do
      assert_equal conditions[:expected], @array.paginate(conditions[:current], conditions[:per_page])
    end
  end
end
