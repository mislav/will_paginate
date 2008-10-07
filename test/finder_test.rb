require 'helper'
require 'lib/activerecord_test_case'

require 'will_paginate'
WillPaginate.enable_activerecord
WillPaginate.enable_named_scope

class FinderTest < ActiveRecordTestCase
  fixtures :topics, :replies, :users, :projects, :developers_projects

  def test_new_methods_presence
    assert_respond_to_all Topic, %w(per_page paginate paginate_by_sql)
  end
  
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
    assert_equal 4, entries.total_pages

    # Developer class has explicit per_page at 10
    entries = Developer.paginate :page => 1
    assert_equal 10, entries.size
    assert_equal 2, entries.total_pages

    entries = Developer.paginate :page => 1, :per_page => 5
    assert_equal 11, entries.total_entries
    assert_equal 5, entries.size
    assert_equal 3, entries.total_pages
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
  
  def test_named_scope_with_include
    project = projects(:active_record)
    entries = project.topics.with_replies_starting_with('AR ').paginate(:page => 1, :per_page => 1)
    assert_equal 1, entries.size
  end

  ## misc ##

  def test_count_and_total_entries_options_are_mutually_exclusive
    e = assert_raise ArgumentError do
      Developer.paginate :page => 1, :count => {}, :total_entries => 1
    end
    assert_match /exclusive/, e.to_s
  end
  
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

  uses_mocha 'internals' do
    def test_implicit_all_with_dynamic_finders
      Topic.expects(:find_all_by_foo).returns([])
      Topic.expects(:count).returns(0)
      Topic.paginate_by_foo :page => 2
    end
    
    def test_guessing_the_total_count
      Topic.expects(:find).returns(Array.new(2))
      Topic.expects(:count).never
      
      entries = Topic.paginate :page => 2, :per_page => 4
      assert_equal 6, entries.total_entries
    end
    
    def test_guessing_that_there_are_no_records
      Topic.expects(:find).returns([])
      Topic.expects(:count).never
      
      entries = Topic.paginate :page => 1, :per_page => 4
      assert_equal 0, entries.total_entries
    end
    
    def test_extra_parameters_stay_untouched
      Topic.expects(:find).with(:all, {:foo => 'bar', :limit => 4, :offset => 0 }).returns(Array.new(5))
      Topic.expects(:count).with({:foo => 'bar'}).returns(1)

      Topic.paginate :foo => 'bar', :page => 1, :per_page => 4
    end

    def test_count_skips_select
      Developer.stubs(:find).returns([])
      Developer.expects(:count).with({}).returns(0)
      Developer.paginate :select => 'salary', :page => 2
    end

    def test_count_select_when_distinct
      Developer.stubs(:find).returns([])
      Developer.expects(:count).with(:select => 'DISTINCT salary').returns(0)
      Developer.paginate :select => 'DISTINCT salary', :page => 2
    end

    def test_count_with_scoped_select_when_distinct
      Developer.stubs(:find).returns([])
      Developer.expects(:count).with(:select => 'DISTINCT users.id').returns(0)
      Developer.distinct.paginate :page => 2
    end

    def test_should_use_scoped_finders_if_present
      # scope-out compatibility
      Topic.expects(:find_best).returns(Array.new(5))
      Topic.expects(:with_best).returns(1)
      
      Topic.paginate_best :page => 1, :per_page => 4
    end

    def test_paginate_by_sql
      assert_respond_to Developer, :paginate_by_sql
      Developer.expects(:find_by_sql).with(regexp_matches(/sql LIMIT 3(,| OFFSET) 3/)).returns([])
      Developer.expects(:count_by_sql).with('SELECT COUNT(*) FROM (sql) AS count_table').returns(0)
      
      entries = Developer.paginate_by_sql 'sql', :page => 2, :per_page => 3
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
      
      Developer.paginate_by_sql "sql\n ORDER\nby foo, bar, `baz` ASC", :page => 2
    end

    # TODO: counts are still wrong
    def test_ability_to_use_with_custom_finders
      # acts_as_taggable defines find_tagged_with(tag, options)
      Topic.expects(:find_tagged_with).with('will_paginate', :offset => 5, :limit => 5).returns([])
      Topic.expects(:count).with({}).returns(0)
      
      Topic.paginate_tagged_with 'will_paginate', :page => 2, :per_page => 5
    end
    
    def test_array_argument_doesnt_eliminate_count
      ids = (1..8).to_a
      Developer.expects(:find_all_by_id).returns([])
      Developer.expects(:count).returns(0)
      
      Developer.paginate_by_id(ids, :per_page => 3, :page => 2, :order => 'id')
    end

    def test_paginating_finder_doesnt_mangle_options
      Developer.expects(:find).returns([])
      options = { :page => 1, :per_page => 2, :foo => 'bar' }
      options_before = options.dup
      
      Developer.paginate(options)
      assert_equal options_before, options
    end
    
    def test_paginate_by_sql_doesnt_change_original_query
      query = 'SQL QUERY'
      original_query = query.dup
      Developer.expects(:find_by_sql).returns([])
      
      Developer.paginate_by_sql query, :page => 1
      assert_equal original_query, query
    end

    def test_paginated_each
      collection = stub('collection', :size => 5, :empty? => false, :per_page => 5)
      collection.expects(:each).times(2).returns(collection)
      last_collection = stub('collection', :size => 4, :empty? => false, :per_page => 5)
      last_collection.expects(:each).returns(last_collection)
      
      params = { :order => 'id', :total_entries => 0 }
      
      Developer.expects(:paginate).with(params.merge(:page => 2)).returns(collection)
      Developer.expects(:paginate).with(params.merge(:page => 3)).returns(collection)
      Developer.expects(:paginate).with(params.merge(:page => 4)).returns(last_collection)
      
      assert_equal 14, Developer.paginated_each(:page => '2') { }
    end

    def test_paginated_each_with_named_scope
      assert_equal 2, Developer.poor.paginated_each(:per_page => 1) {
        assert_equal 11, Developer.count
      }
    end

    # detect ActiveRecord 2.1
    if ActiveRecord::Base.private_methods.include?('references_eager_loaded_tables?')
      def test_removes_irrelevant_includes_in_count
        Developer.expects(:find).returns([1])
        Developer.expects(:count).with({}).returns(0)

        Developer.paginate :page => 1, :per_page => 1, :include => :projects
      end

      def test_doesnt_remove_referenced_includes_in_count
        Developer.expects(:find).returns([1])
        Developer.expects(:count).with({ :include => :projects, :conditions => 'projects.id > 2' }).returns(0)

        Developer.paginate :page => 1, :per_page => 1,
          :include => :projects, :conditions => 'projects.id > 2'
      end
    end
    
    def test_paginate_from
      result = Developer.paginate(:from => 'users', :page => 1, :per_page => 1)
      assert_equal 1, result.size
    end
    
    def test_hmt_with_include
      # ticket #220
      reply = projects(:active_record).replies.find(:first, :order => 'replies.id')
      assert_equal replies(:decisive), reply
      
      # ticket #223
      Project.find(1, :include => :replies)
      
      # I cannot reproduce any of the failures from those reports :(
    end
  end
end
