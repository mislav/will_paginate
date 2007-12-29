require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/lib/activerecord_test_case'

require 'will_paginate'
WillPaginate.enable_activerecord

class FinderTest < ActiveRecordTestCase
  fixtures :topics, :replies, :users, :projects, :developers_projects

  def test_new_methods_presence
    assert_respond_to_all Topic, %w(per_page paginate paginate_by_sql)
  end
  
  def test_simple_paginate
    entries = Topic.paginate :page => nil
    assert_equal 1, entries.current_page
    assert_nil entries.previous_page
    assert_nil entries.next_page
    assert_equal 1, entries.page_count
    assert_equal 4, entries.size
    
    entries = Topic.paginate :page => 2
    assert_equal 2, entries.current_page
    assert_equal 1, entries.previous_page
    assert_equal 1, entries.page_count
    assert entries.empty?
  end

  def test_parameter_api
    # :page parameter in options is required!
    assert_raise(ArgumentError){ Topic.paginate }
    assert_raise(ArgumentError){ Topic.paginate({}) }
    
    # explicit :all should not break anything
    assert_equal Topic.paginate(:page => nil), Topic.paginate(:all, :page => 1)

    # :count could be nil and we should still not cry
    assert_nothing_raised { Topic.paginate :page => 1, :count => nil }
  end
  
  def test_paginate_with_per_page
    entries = Topic.paginate :page => 1, :per_page => 1
    assert_equal 1, entries.size
    assert_equal 4, entries.page_count

    # Developer class has explicit per_page at 10
    entries = Developer.paginate :page => 1
    assert_equal 10, entries.size
    assert_equal 2, entries.page_count

    entries = Developer.paginate :page => 1, :per_page => 5
    assert_equal 11, entries.total_entries
    assert_equal 5, entries.size
    assert_equal 3, entries.page_count
  end
  
  def test_paginate_with_order
    entries = Topic.paginate :page => 1, :order => 'created_at desc'
    expected = [topics(:futurama), topics(:harvey_birdman), topics(:rails), topics(:ar)].reverse
    assert_equal expected, entries.to_a
    assert_equal 1, entries.page_count
  end
  
  def test_paginate_with_conditions
    entries = Topic.paginate :page => 1, :conditions => ["created_at > ?", 30.minutes.ago]
    expected = [topics(:rails), topics(:ar)]
    assert_equal expected, entries.to_a
    assert_equal 1, entries.page_count
  end

  def test_paginate_with_include_and_conditions
    entries = Topic.paginate \
      :page     => 1, 
      :include  => :replies,  
      :conditions => "replies.content LIKE 'Bird%' ", 
      :per_page => 10

    expected = Topic.find :all, 
      :include => 'replies', 
      :conditions => "replies.content LIKE 'Bird%' ", 
      :limit   => 10

    assert_equal expected, entries.to_a
    assert_equal 1, entries.total_entries
  end
  
  def test_paginate_with_include_and_order
    entries = Topic.paginate \
      :page     => 1, 
      :include  => :replies,  
      :order    => 'replies.created_at asc, topics.created_at asc', 
      :per_page => 10

    expected = Topic.find :all, 
      :include => 'replies', 
      :order   => 'replies.created_at asc, topics.created_at asc', 
      :limit   => 10

    assert_equal expected, entries.to_a
    assert_equal 4, entries.total_entries
  end

  def test_paginate_associations_with_include
    entries, project = nil, projects(:active_record)

    assert_nothing_raised "THIS IS A BUG in Rails 1.2.3 that was fixed in [7326]. " +
        "Please upgrade to the 1-2-stable branch or edge Rails." do
      entries = project.topics.paginate \
        :page     => 1, 
        :include  => :replies,  
        :conditions => "replies.content LIKE 'Nice%' ", 
        :per_page => 10
    end

    expected = Topic.find :all, 
      :include => 'replies', 
      :conditions => "project_id = #{project.id} AND replies.content LIKE 'Nice%' ", 
      :limit   => 10

    assert_equal expected, entries.to_a
  end

  def test_paginate_associations
    dhh = users :david
    expected_name_ordered = [projects(:action_controller), projects(:active_record)]
    expected_id_ordered   = [projects(:active_record), projects(:action_controller)]

    # with association-specified order
    entries = dhh.projects.paginate(:page => 1)
    assert_equal expected_name_ordered, entries
    assert_equal 2, entries.total_entries

    # with explicit order
    entries = dhh.projects.paginate(:page => 1, :order => 'projects.id')
    assert_equal expected_id_ordered, entries
    assert_equal 2, entries.total_entries

    assert_nothing_raised { dhh.projects.find(:all, :order => 'projects.id', :limit => 4) }
    entries = dhh.projects.paginate(:page => 1, :order => 'projects.id', :per_page => 4)
    assert_equal expected_id_ordered, entries

    # has_many with implicit order
    topic = Topic.find(1)
    expected = [replies(:spam), replies(:witty_retort)]
    assert_equal expected.map(&:id).sort, topic.replies.paginate(:page => 1).map(&:id).sort
    assert_equal expected.reverse, topic.replies.paginate(:page => 1, :order => 'replies.id ASC')
  end

  def test_paginate_association_extension
    project = Project.find(:first)
    entries = project.replies.paginate_recent :page => 1
    assert_equal [replies(:brave)], entries
  end
  
  def test_paginate_with_joins
    entries = Developer.paginate :page => 1,
                        :joins => 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id',
                        :conditions => 'project_id = 1'        
    assert_equal 2, entries.size
    developer_names = entries.map { |d| d.name }
    assert developer_names.include?('David')
    assert developer_names.include?('Jamis')

    expected = entries.to_a
    entries = Developer.paginate :page => 1,
                        :joins => 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id',
                        :conditions => 'project_id = 1', :count => { :select => "users.id" }
    assert_equal expected, entries.to_a
  end

  def test_paginate_with_group
    entries = Developer.paginate :page => 1, :per_page => 10, :group => 'salary'
    expected = [ users(:david), users(:jamis), users(:dev_10), users(:poor_jamis) ].map(&:salary).sort
    assert_equal expected, entries.map(&:salary).sort
  end

  def test_paginate_with_dynamic_finder
    expected = [replies(:witty_retort), replies(:spam)]
    assert_equal expected, Reply.paginate_by_topic_id(1, :page => 1)

    entries = Developer.paginate :conditions => { :salary => 100000 }, :page => 1, :per_page => 5
    assert_equal 8, entries.total_entries
    assert_equal entries, Developer.paginate_by_salary(100000, :page => 1, :per_page => 5)

    # dynamic finder + conditions
    entries = Developer.paginate_by_salary(100000, :page => 1,
                                           :conditions => ['id > ?', 6])
    assert_equal 4, entries.total_entries
    assert_equal (7..10).to_a, entries.map(&:id)

    assert_raises NoMethodError do
      Developer.paginate_by_inexistent_attribute 100000, :page => 1
    end
  end

  def test_count_distinct
    entries = Developer.paginate :select => 'DISTINCT salary', :page => 1, :per_page => 4
    assert_equal 4, entries.size
    assert_equal 4, entries.total_entries
  end

  def test_scoped_paginate
    entries = Developer.with_poor_ones { Developer.paginate :page => 1 }

    assert_equal 2, entries.size
    assert_equal 2, entries.total_entries
  end

  # Are we on edge? Find out by testing find_all which was removed in [6998]
  unless Developer.respond_to? :find_all
    def test_paginate_array_of_ids
      # AR finders also accept arrays of IDs
      # (this was broken in Rails before [6912])
      entries = Developer.paginate((1..8).to_a, :per_page => 3, :page => 2)
      assert_equal (4..6).to_a, entries.map(&:id)
      assert_equal 8, entries.total_entries
    end
  end

  uses_mocha 'internals' do
    def test_implicit_all_with_dynamic_finders
      Topic.expects(:find_all_by_foo).returns([])
      Topic.expects(:wp_extract_finder_conditions)
      Topic.expects(:count)
      Topic.paginate_by_foo :page => 1
    end
    
    def test_guessing_the_total_count
      Topic.expects(:find).returns(Array.new(2))
      Topic.expects(:count).never
      
      entries = Topic.paginate :page => 2, :per_page => 4
      assert_equal 6, entries.total_entries
    end
    
    def test_extra_parameters_stay_untouched
      Topic.expects(:find).with() { |*args| args.last.key? :foo }.returns(Array.new(5))
      Topic.expects(:count).with(){ |*args| args.last.key? :foo }.returns(1)

      Topic.paginate :foo => 'bar', :page => 1, :per_page => 4
    end

    def test_count_doesnt_use_select_options
      Developer.expects(:find).with() { |*args| args.last.key? :select }.returns(Array.new(5))
      Developer.expects(:count).with(){ |*args| !args.last.key? :select }.returns(1)
      
      Developer.paginate :select => 'users.*', :page => 1, :per_page => 4
    end

    def test_should_use_scoped_finders_if_present
      # scope-out compatibility
      Topic.expects(:find_best).returns(Array.new(5))
      Topic.expects(:with_best).returns(1)
      
      Topic.paginate_best :page => 1, :per_page => 4
    end

    def test_ability_to_use_with_custom_finders
      # acts_as_taggable defines `find_tagged_with(tag, options)`
      Topic.expects(:find_tagged_with).with('will_paginate', :offset => 0, :limit => 5).returns([])
      Topic.expects(:count).with({}).returns(0)
      
      Topic.paginate_tagged_with 'will_paginate', :page => 1, :per_page => 5
    end

    def test_paginate_by_sql
      assert_respond_to Developer, :paginate_by_sql
      Developer.expects(:find_by_sql).with('sql LIMIT 3 OFFSET 3').returns([])
      Developer.expects(:count_by_sql).with('SELECT COUNT(*) FROM (sql) AS count_table').returns(0)
      
      entries = Developer.paginate_by_sql 'sql', :page => 2, :per_page => 3
      assert_equal 0, entries.total_entries
    end

    def test_paginate_by_sql_respects_total_entries_setting
      Developer.expects(:find_by_sql).returns([])
      Developer.expects(:count_by_sql).never
      
      entries = Developer.paginate_by_sql 'sql', :page => 1, :total_entries => 999
      assert_equal 999, entries.total_entries
    end

    def test_paginate_by_sql_strips_order_by_when_counting
      Developer.expects(:find_by_sql).returns([])
      Developer.expects(:count_by_sql).with("SELECT COUNT(*) FROM (sql\n ) AS count_table").returns(0)
      
      entries = Developer.paginate_by_sql "sql\n ORDER\nby foo, bar, `baz` ASC", :page => 1
    end
  end
end
