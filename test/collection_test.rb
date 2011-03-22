require 'helper'
require 'will_paginate/array'

class ArrayPaginationTest < Test::Unit::TestCase
  
  def setup ; end
  
  def test_simple
    collection = ('a'..'e').to_a
    
    [{ :page => 1,  :per_page => 3,  :expected => %w( a b c ) },
     { :page => 2,  :per_page => 3,  :expected => %w( d e ) },
     { :page => 1,  :per_page => 5,  :expected => %w( a b c d e ) },
     { :page => 3,  :per_page => 5,  :expected => [] },
    ].
    each do |conditions|
      expected = conditions.delete :expected
      assert_equal expected, collection.paginate(conditions)
    end
  end

  def test_defaults
    result = (1..50).to_a.paginate
    assert_equal 1, result.current_page
    assert_equal 30, result.size
  end

  def test_deprecated_api
    assert_raise(ArgumentError) { [].paginate(2) }
    assert_raise(ArgumentError) { [].paginate(2, 10) }
  end

  def test_total_entries_has_precedence
    result = %w(a b c).paginate :total_entries => 5
    assert_equal 5, result.total_entries
  end

  def test_argument_error_with_params_and_another_argument
    assert_raise ArgumentError do
      [].paginate({}, 5)
    end
  end

  def test_paginated_collection
    entries = %w(a b c)
    collection = create(2, 3, 10) do |pager|
      assert_equal entries, pager.replace(entries)
    end

    assert_equal entries, collection
    assert_respond_to_all collection, %w(total_pages each offset size current_page per_page total_entries)
    assert_kind_of Array, collection
    assert_instance_of Array, collection.entries
    assert_equal 3, collection.offset
    assert_equal 4, collection.total_pages
    assert !collection.out_of_bounds?
  end

  def test_previous_next_pages
    collection = create(1, 1, 3)
    assert_nil collection.previous_page
    assert_equal 2, collection.next_page
    
    collection = create(2, 1, 3)
    assert_equal 1, collection.previous_page
    assert_equal 3, collection.next_page
    
    collection = create(3, 1, 3)
    assert_equal 2, collection.previous_page
    assert_nil collection.next_page
  end

  def test_out_of_bounds
    entries = create(2, 3, 2){}
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
    
    entries = create(1) do |pager|
      # collection is empty and we're on page 1,
      # so the whole thing must be empty, too
      pager.replace array(0)
    end
    assert_equal 0, entries.total_entries
  end

  def test_invalid_page
    bad_inputs = [0, -1, nil, '', 9223372036854775808, 'Schnitzel']

    bad_inputs.each do |bad|
      assert_raise(WillPaginate::InvalidPage) { create bad }
    end
  end

  def test_invalid_per_page
    bad_inputs = [0, -1, 9223372036854775808, 'Schnitzel']

    bad_inputs.each do |bad|
      assert_raise(ArgumentError) { create(1, bad) }
    end
  end

  def test_invalid_total_entries
    bad_inputs = [-1, 9223372036854775808, 'Schnitzel']

    bad_inputs.each do |bad|
      assert_raise(ArgumentError) { create(1, 1, bad) }
    end
  end

  def test_page_count_was_removed
    assert_raise(NoMethodError) { create.page_count }
    # It's `total_pages` now.
  end

  private
    def create(page = 2, limit = 5, total = nil, &block)
      if block_given?
        WillPaginate::Collection.create(page, limit, total, &block)
      else
        WillPaginate::Collection.new(page, limit, total)
      end
    end

    def array(size = 3)
      Array.new(size)
    end
end
