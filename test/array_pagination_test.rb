require File.dirname(__FILE__) + '/helper'
require 'will_paginate/core_ext'

class ArrayPaginationTest < Test::Unit::TestCase
  def test_simple
    collection = ('a'..'e').to_a
    
    [{ :page => 1,  :per_page => 3,  :expected => %w( a b c ) },
     { :page => 2,  :per_page => 3,  :expected => %w( d e ) },
     { :page => 1,  :per_page => 5,  :expected => %w( a b c d e ) },
     { :page => 3,  :per_page => 5,  :expected => [] },
    ].
    each do |conditions|
      assert_equal conditions[:expected], collection.paginate(conditions.slice(:page, :per_page))
    end
  end

  def test_defaults
    result = (1..50).to_a.paginate
    assert_equal 1, result.current_page
    assert_equal 30, result.size
  end

  def test_deprecated_api
    assert_deprecated 'paginate API' do
      result = (1..50).to_a.paginate(2, 10)
      assert_equal 2, result.current_page
      assert_equal (11..20).to_a, result
      assert_equal 50, result.total_entries
    end
    
    assert_deprecated { [].paginate nil }
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

  def test_invalid_page
    bad_input = [0, -1, nil, '', 'Schnitzel']

    bad_input.each do |bad|
      assert_raise(WillPaginate::InvalidPage) { create(bad) }
    end
  end

  def test_invalid_per_page_setting
    assert_raise(ArgumentError) { create(1, -1) }
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
    
    def collect_deprecations
      old_behavior = WillPaginate::Deprecation.behavior
      deprecations = []
      WillPaginate::Deprecation.behavior = Proc.new do |message, callstack|
        deprecations << message
      end
      result = yield
      [result, deprecations]
    ensure
      WillPaginate::Deprecation.behavior = old_behavior
    end
end
