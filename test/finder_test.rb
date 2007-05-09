require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class PaginationTest < ActiveRecordTestCase
  fixtures :topics, :replies, :developers, :projects, :developers_projects
  
  def test_simple_paginate
    @entries = Topic.paginate
    assert_equal 1, @entries.current_page
    assert_equal 1, @entries.page_count
    assert_equal 3, @entries.size

    @entries = Topic.paginate :page => 2
    assert_equal 2, @entries.current_page
    assert_equal 1, @entries.page_count
    assert @entries.empty?

    @entries = Reply.paginate_all_by_topic_id(1)
    expected = [replies(:witty_retort), replies(:spam)]
    assert_equal expected, @entries.to_a
    @entries = Reply.paginate_by_topic_id(1)
    assert_equal expected, @entries.to_a
  end
  
  def test_paginate_with_per_page
    @entries = Topic.paginate :per_page => 1
    assert_equal 1, @entries.size
    assert_equal 3, @entries.page_count

    # Developer class has explicit per_page at 10
    @entries = Developer.paginate
    assert_equal 10, @entries.size
    assert_equal 2, @entries.page_count

    @entries = Developer.paginate :per_page => 5
    assert_equal 11, @entries.total_entries
    assert_equal 5, @entries.size
    assert_equal 3, @entries.page_count
  end
  
  def test_paginate_with_order
    @entries = Topic.paginate :order => 'created_at asc'
    expected = [topics(:futurama), topics(:harvey_birdman), topics(:rails)]
    assert_equal expected, @entries.to_a
    assert_equal 1, @entries.page_count
  end
  
  def test_paginate_with_conditions
    @entries = Topic.paginate :conditions => ["created_at > ?", 30.minutes.ago]
    expected = [topics(:rails)]
    assert_equal expected, @entries.to_a
    assert_equal 1, @entries.page_count
  end
  
  def test_paginate_with_joins
    @entries = Developer.paginate :joins => 'LEFT JOIN developers_projects ON developers.id = developers_projects.developer_id',
                                  :conditions => 'project_id=1'        
    assert_equal 2, @entries.size
    developer_names = @entries.map { |d| d.name }
    assert developer_names.include?('David')
    assert developer_names.include?('Jamis')

    expected = @entries.to_a
    @entries = Developer.paginate :joins => 'd LEFT JOIN developers_projects ON d.id = developers_projects.developer_id',
                                  :conditions => 'project_id=1',
                                  :count => "d.id"        
    assert_equal expected, @entries.to_a
  end
  
  def test_paginate_with_include_and_order
    @entries = Topic.paginate   :include => :replies,  :order => 'replies.created_at asc, topics.created_at asc', :per_page => 10
    expected = Topic.find :all, :include => 'replies', :order => 'replies.created_at asc, topics.created_at asc', :limit => 10
    assert_equal expected, @entries.to_a
  end
end
