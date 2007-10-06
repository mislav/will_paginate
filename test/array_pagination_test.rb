require File.dirname(__FILE__) + '/helper'
require 'will_paginate/core_ext'

class ArrayPaginationTest < Test::Unit::TestCase
  def test_simple
    collection = ('a'..'e').to_a
    
    [{ :current => 1,  :per_page => 3,  :expected => %w( a b c ) },
     { :current => 2,  :per_page => 3,  :expected => %w( d e ) },
     { :current => 1,  :per_page => 5,  :expected => %w( a b c d e ) },
     { :current => 3,  :per_page => 5,  :expected => [] },
     { :current => -1, :per_page => 5,  :expected => [] },
     { :current => 1,  :per_page => -5, :expected => [] },
    ].
    each do |conditions|
      assert_equal conditions[:expected], collection.paginate(conditions[:current], conditions[:per_page])
    end
  end

  def test_defaults
    result = ('a'..'z').to_a.paginate
    assert_equal 1, result.current_page
    assert_equal 15, result.size
  end

  def test_paginated_collection
    entries = %w(a b c)
    collection = create(2, 3, 10) do |pager|
      pager.replace entries
    end

    assert_equal entries, collection
    assert_respond_to_all collection, %w(page_count each offset size current_page per_page total_entries)
    assert_kind_of Array, collection
    assert_instance_of Array, collection.entries
    assert_equal 3, collection.offset
    assert_equal 4, collection.page_count
    assert !collection.out_of_bounds?
  end

  def test_out_of_bounds
    entries = create(2, 3, 2){}
    assert entries.out_of_bounds?
    
    entries = create(0, 3, 2){}
    assert entries.out_of_bounds?
    
    entries = create(1, 3, 2){}
    assert !entries.out_of_bounds?
  end

  def test_guessing_total_count
    entries = create do |pager|
      # collection is shorter than limit
      pager.replace array
    end
    assert_equal 8, entries.total_entries
    
    entries = create(2, 5, 10) do |pager|
      # collection is shorter than limit, but we have an explicit count
      pager.replace array
    end
    assert_equal 10, entries.total_entries
    
    entries = create do |pager|
      # collection is the same as limit; we can't guess
      pager.replace array(5)
    end
    assert_equal nil, entries.total_entries
    
    entries = create do |pager|
      # collection is empty; we can't guess
      pager.replace array(0)
    end
    assert_equal nil, entries.total_entries
  end

  private

    def create(page = 2, limit = 5, total = nil, &block)
      WillPaginate::Collection.create(page, limit, total, &block)
    end

    def array(size = 3)
      Array.new(size)
    end
end
