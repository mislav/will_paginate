require 'helper'
require 'lib/activerecord_test_case'

require 'will_paginate'
require 'will_paginate/finders/active_record'
WillPaginate.enable_named_scope

class FinderTest < ActiveRecordTestCase
  fixtures :topics, :replies, :users, :projects, :developers_projects

  def test_simple_paginate
    assert_queries(1) do
      entries = Topic.paginate :page => nil
      assert_equal 1, entries.current_page
      assert_equal 1, entries.total_pages
      assert_equal 4, entries.size
    end
    
    assert_queries(2) do
      entries = Topic.paginate :page => 2
      assert_equal 1, entries.total_pages
      assert entries.empty?
    end
  end
  
  def test_paginate_with_order
    entries = Topic.paginate :page => 1, :order => 'created_at desc'
    expected = [topics(:futurama), topics(:harvey_birdman), topics(:rails), topics(:ar)].reverse
    assert_equal expected, entries.to_a
    assert_equal 1, entries.total_pages
  end
  
  def test_paginate_with_conditions
    entries = Topic.paginate :page => 1, :conditions => ["created_at > ?", 30.minutes.ago]
    expected = [topics(:rails), topics(:ar)]
    assert_equal expected, entries.to_a
    assert_equal 1, entries.total_pages
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
    entries = nil
    assert_queries(2) do
      entries = Topic.paginate \
        :page     => 1, 
        :include  => :replies,  
        :order    => 'replies.created_at asc, topics.created_at asc', 
        :per_page => 10
    end

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
        "Please upgrade to a newer version of Rails." do
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

    assert_queries(2) do
      # with association-specified order
      entries = dhh.projects.paginate(:page => 1)
      assert_equal expected_name_ordered, entries
      assert_equal 2, entries.total_entries
    end

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
    
    assert_queries(2) do
      entries = project.replies.paginate_recent :page => 1
      assert_equal [replies(:brave)], entries
    end
  end
  
  def test_paginate_with_joins
    entries = nil
    
    assert_queries(1) do
      entries = Developer.paginate :page => 1,
                          :joins => 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id',
                          :conditions => 'project_id = 1'        
      assert_equal 2, entries.size
      developer_names = entries.map &:name
      assert developer_names.include?('David')
      assert developer_names.include?('Jamis')
    end

    assert_queries(1) do
      expected = entries.to_a
      entries = Developer.paginate :page => 1,
                          :joins => 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id',
                          :conditions => 'project_id = 1', :count => { :select => "users.id" }
      assert_equal expected, entries.to_a
      assert_equal 2, entries.total_entries
    end
  end

  def test_paginate_with_group
    entries = nil
    assert_queries(1) do
      entries = Developer.paginate :page => 1, :per_page => 10,
                                   :group => 'salary', :select => 'salary', :order => 'salary'
    end
    
    expected = [ users(:david), users(:jamis), users(:dev_10), users(:poor_jamis) ].map(&:salary).sort
    assert_equal expected, entries.map(&:salary)
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

  def test_scoped_paginate
    entries = Developer.with_poor_ones { Developer.paginate :page => 1 }

    assert_equal 2, entries.size
    assert_equal 2, entries.total_entries
  end

  ## named_scope ##
  
  def test_paginate_in_named_scope
    entries = Developer.poor.paginate :page => 1, :per_page => 1

    assert_equal 1, entries.size
    assert_equal 2, entries.total_entries
  end
  
  def test_paginate_in_named_scope_on_habtm_association
    project = projects(:active_record)
    assert_queries(2) do
      entries = project.developers.poor.paginate :page => 1, :per_page => 1

      assert_equal 1, entries.size, 'one developer should be found'
      assert_equal 1, entries.total_entries, 'only one developer should be found'
    end
  end

  def test_paginate_in_named_scope_on_hmt_association
    project = projects(:active_record)
    expected = [replies(:brave)]
    
    assert_queries(2) do
      entries = project.replies.recent.paginate :page => 1, :per_page => 1
      assert_equal expected, entries
      assert_equal 1, entries.total_entries, 'only one reply should be found'
    end
  end

  def test_paginate_in_named_scope_on_has_many_association
    project = projects(:active_record)
    expected = [topics(:ar)]
    
    assert_queries(2) do
      entries = project.topics.mentions_activerecord.paginate :page => 1, :per_page => 1
      assert_equal expected, entries
      assert_equal 1, entries.total_entries, 'only one topic should be found'
    end
  end

  ## misc ##
  
  def test_readonly
    assert_nothing_raised { Developer.paginate :readonly => true, :page => 1 }
  end

  # this functionality is temporarily removed
  def xtest_pagination_defines_method
    pager = "paginate_by_created_at"
    assert !User.methods.include?(pager), "User methods should not include `#{pager}` method"
    # paginate!
    assert 0, User.send(pager, nil, :page => 1).total_entries
    # the paging finder should now be defined
    assert User.methods.include?(pager), "`#{pager}` method should be defined on User"
  end

  # Is this Rails 2.0? Find out by testing find_all which was removed in [6998]
  unless ActiveRecord::Base.respond_to? :find_all
    def test_paginate_array_of_ids
      # AR finders also accept arrays of IDs
      # (this was broken in Rails before [6912])
      assert_queries(1) do
        entries = Developer.paginate((1..8).to_a, :per_page => 3, :page => 2, :order => 'id')
        assert_equal (4..6).to_a, entries.map(&:id)
        assert_equal 8, entries.total_entries
      end
    end
  end
end
