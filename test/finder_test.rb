require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class FinderTest < ActiveRecordTestCase
  fixtures :topics, :replies, :developers, :projects, :developers_projects

  def test_new_methods_presence
    assert_respond_to_all Topic, %w(per_page paginate paginate_by_sql)
  end

  def test_paginated_collection
    entries = %w(a b c)
    collection = WillPaginate::Collection.new 2, 3, 10
    collection.replace entries

    assert_equal entries, collection
    assert_respond_to_all collection, %w(page_count each offset size current_page per_page total_entries)
    assert_equal Array, collection.entries.class
    assert_equal 3, collection.offset
  end
  
  def test_simple_paginate
    entries = Topic.paginate
    assert_equal 1, entries.current_page
    assert_nil entries.previous_page
    assert_nil entries.next_page
    assert_equal 1, entries.page_count
    assert_equal 3, entries.size

    entries = Topic.paginate :page => 2
    assert_equal 2, entries.current_page
    assert_equal 1, entries.previous_page
    assert_equal 1, entries.page_count
    assert entries.empty?

    entries = Reply.paginate_all_by_topic_id(1)
    expected = [replies(:witty_retort), replies(:spam)]
    assert_equal expected, entries.to_a
    entries = Reply.paginate_by_topic_id(1)
    assert_equal expected, entries.to_a
  end
  
  def test_paginate_with_per_page
    entries = Topic.paginate :per_page => 1
    assert_equal 1, entries.size
    assert_equal 3, entries.page_count

    # Developer class has explicit per_page at 10
    entries = Developer.paginate
    assert_equal 10, entries.size
    assert_equal 2, entries.page_count

    entries = Developer.paginate :per_page => 5
    assert_equal 11, entries.total_entries
    assert_equal 5, entries.size
    assert_equal 3, entries.page_count
  end
  
  def test_paginate_with_order
    entries = Topic.paginate :order => 'created_at asc'
    expected = [topics(:futurama), topics(:harvey_birdman), topics(:rails)]
    assert_equal expected, entries.to_a
    assert_equal 1, entries.page_count
  end
  
  def test_paginate_with_conditions
    entries = Topic.paginate :conditions => ["created_at > ?", 30.minutes.ago]
    expected = [topics(:rails)]
    assert_equal expected, entries.to_a
    assert_equal 1, entries.page_count
  end
  
  def test_paginate_with_joins
    entries = Developer.paginate :joins => 'LEFT JOIN developers_projects ON developers.id = developers_projects.developer_id',
                                  :conditions => 'project_id=1'        
    assert_equal 2, entries.size
    developer_names = entries.map { |d| d.name }
    assert developer_names.include?('David')
    assert developer_names.include?('Jamis')

    expected = entries.to_a
    entries = Developer.paginate :joins => 'd LEFT JOIN developers_projects ON d.id = developers_projects.developer_id',
                                  :conditions => 'project_id=1',
                                  :count => { :select => "d.id" }
    assert_equal expected, entries.to_a
  end
  
  def test_paginate_with_include_and_order
    entries = Topic.paginate   :include => :replies,  :order => 'replies.created_at asc, topics.created_at asc', :per_page => 10
    expected = Topic.find :all, :include => 'replies', :order => 'replies.created_at asc, topics.created_at asc', :limit => 10
    assert_equal expected, entries.to_a
  end

  def test_paginate_with_group
    entries = Developer.paginate :per_page => 10, :group => 'salary'
    expected = [ developers(:david), developers(:jamis), developers(:dev_10), developers(:poor_jamis) ].sort_by(&:salary)
    assert_equal expected, entries.to_a.sort_by(&:salary)
  end

  def test_paginate_with_dynamic_finder
    entries = Developer.paginate :conditions => { :salary => 100000 }, :per_page => 5
    assert_equal 8, entries.total_entries

    entries = Developer.paginate_by_salary 100000, :per_page => 5
    assert_equal 8, entries.total_entries

    assert_raises StandardError do
      Developer.paginate_by_gallery 100000, :per_page => 5
    end
  end

protected

  def assert_respond_to_all object, methods
    methods.each do |method|
      [method.to_s, method.to_sym].each {|m| assert_respond_to object, m }
    end
  end
end
