require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class ArrayPaginationTest < Test::Unit::TestCase
  def test_simple
    array = ('a'..'e').to_a
    
    [{ :current => 1,  :per_page => 3,  :expected => %w( a b c ) },
     { :current => 2,  :per_page => 3,  :expected => %w( d e ) },
     { :current => 1,  :per_page => 5,  :expected => %w( a b c d e ) },
     { :current => 3,  :per_page => 5,  :expected => [] },
     { :current => -1, :per_page => 5,  :expected => [] },
     { :current => 1,  :per_page => -5, :expected => [] },
    ].
    each do |conditions|
      assert_equal conditions[:expected], array.paginate(conditions[:current], conditions[:per_page])
    end
  end

  def test_defaults
    array = ('a'..'z').to_a

    result = array.paginate
    assert_equal 1, result.current_page
    assert_equal 15, result.size
  end
end
