require 'spec_helper'
require 'will_paginate/finders/active_record'
require File.dirname(__FILE__) + '/activerecord_test_connector'

require 'will_paginate'
WillPaginate::enable_named_scope

class ArProject < ActiveRecord::Base
  def self.column_names
    ["id"]
  end
  
  named_scope :distinct, :select => "DISTINCT #{table_name}.*"
end

gem 'sqlite3-ruby'
ActiverecordTestConnector.setup

describe WillPaginate::Finders::ActiveRecord do
  
  extend ActiverecordTestConnector::FixtureSetup
  
  it "should integrate with ActiveRecord::Base" do
    ActiveRecord::Base.should respond_to(:paginate)
  end
  
  it "should paginate" do
    ArProject.expects(:find).with(:all, { :limit => 5, :offset => 0 }).returns([])
    ArProject.paginate(:page => 1, :per_page => 5)
  end
  
  it "should respond to paginate_by_sql" do
    ArProject.should respond_to(:paginate_by_sql)
  end
  
  it "should support explicit :all argument" do
    ArProject.expects(:find).with(:all, instance_of(Hash)).returns([])
    ArProject.paginate(:all, :page => nil)
  end
  
  it "should put implicit all in dynamic finders" do
    ArProject.expects(:find_all_by_foo).returns([])
    ArProject.expects(:count).returns(0)
    ArProject.paginate_by_foo :page => 2
  end
  
  it "should leave extra parameters intact" do
    ArProject.expects(:find).with(:all, {:foo => 'bar', :limit => 4, :offset => 0 }).returns(Array.new(5))
    ArProject.expects(:count).with({:foo => 'bar'}).returns(1)

    ArProject.paginate :foo => 'bar', :page => 1, :per_page => 4
  end

  describe "counting" do
    it "should ignore nil in :count parameter" do
      ArProject.expects(:find).returns([])
      lambda { ArProject.paginate :page => nil, :count => nil }.should_not raise_error
    end
    
    it "should guess the total count" do
      ArProject.expects(:find).returns(Array.new(2))
      ArProject.expects(:count).never

      result = ArProject.paginate :page => 2, :per_page => 4
      result.total_entries.should == 6
    end

    it "should guess that there are no records" do
      ArProject.expects(:find).returns([])
      ArProject.expects(:count).never

      result = ArProject.paginate :page => 1, :per_page => 4
      result.total_entries.should == 0
    end
  end
  
  it "should not ignore :select parameter when it says DISTINCT" do
    ArProject.stubs(:find).returns([])
    ArProject.expects(:count).with(:select => 'DISTINCT salary').returns(0)
    ArProject.paginate :select => 'DISTINCT salary', :page => 2
  end
  
  it "should count with scoped select when :select => DISTINCT" do
    ArProject.stubs(:find).returns([])
    ArProject.expects(:count).with(:select => 'DISTINCT ar_projects.id').returns(0)
    ArProject.distinct.paginate :page => 2
  end

  it "should use :with_foo for scope-out compatibility" do
    ArProject.expects(:find_best).returns(Array.new(5))
    ArProject.expects(:with_best).returns(1)
    
    ArProject.paginate_best :page => 1, :per_page => 4
  end

  describe "paginate_by_sql" do
    it "should paginate" do
      ArProject.expects(:find_by_sql).with(regexp_matches(/sql LIMIT 3(,| OFFSET) 3/)).returns([])
      ArProject.expects(:count_by_sql).with('SELECT COUNT(*) FROM (sql) AS count_table').returns(0)
    
      ArProject.paginate_by_sql 'sql', :page => 2, :per_page => 3
    end

    it "should respect total_entrier setting" do
      ArProject.expects(:find_by_sql).returns([])
      ArProject.expects(:count_by_sql).never
    
      entries = ArProject.paginate_by_sql 'sql', :page => 1, :total_entries => 999
      entries.total_entries.should == 999
    end

    it "should strip the order when counting" do
      ArProject.expects(:find_by_sql).returns([])
      ArProject.expects(:count_by_sql).with("SELECT COUNT(*) FROM (sql\n ) AS count_table").returns(0)
    
      ArProject.paginate_by_sql "sql\n ORDER\nby foo, bar, `baz` ASC", :page => 2
    end
    
    it "shouldn't change the original query string" do
      query = 'SQL QUERY'
      original_query = query.dup
      ArProject.expects(:find_by_sql).returns([])
      
      ArProject.paginate_by_sql(query, :page => 1)
      query.should == original_query
    end
  end

  # TODO: counts would still be wrong!
  it "should be able to paginate custom finders" do
    # acts_as_taggable defines find_tagged_with(tag, options)
    ArProject.expects(:find_tagged_with).with('will_paginate', :offset => 5, :limit => 5).returns([])
    ArProject.expects(:count).with({}).returns(0)
    
    ArProject.paginate_tagged_with 'will_paginate', :page => 2, :per_page => 5
  end

  it "should not skip count when given an array argument to a finder" do
    ids = (1..8).to_a
    ArProject.expects(:find_all_by_id).returns([])
    ArProject.expects(:count).returns(0)
    
    ArProject.paginate_by_id(ids, :per_page => 3, :page => 2, :order => 'id')
  end

  it "doesn't mangle options" do
    ArProject.expects(:find).returns([])
    options = { :page => 1 }
    options.expects(:delete).never
    options_before = options.dup
    
    ArProject.paginate(options)
    options.should == options_before
  end
  
  if ::ActiveRecord::Calculations::CALCULATIONS_OPTIONS.include?(:from)
    # for ActiveRecord 2.1 and newer
    it "keeps the :from parameter in count" do
      ArProject.expects(:find).returns([1])
      ArProject.expects(:count).with {|options| options.key?(:from) }.returns(0)
      ArProject.paginate(:page => 2, :per_page => 1, :from => 'projects')
    end
  else
    it "excludes :from parameter from count" do
      ArProject.expects(:find).returns([1])
      ArProject.expects(:count).with {|options| !options.key?(:from) }.returns(0)
      ArProject.paginate(:page => 2, :per_page => 1, :from => 'projects')
    end
  end
  
  if ActiverecordTestConnector.able_to_connect
    fixtures :topics, :replies, :users, :projects, :developers_projects
    
    it "should get first page of Topics with a single query" do
      lambda {
        result = Topic.paginate :page => nil
        result.current_page.should == 1
        result.total_pages.should == 1
        result.size.should == 4
      }.should run_queries(1)
    end
    
    it "should get second (inexistent) page of Topics, requiring 2 queries" do
      lambda {
        result = Topic.paginate :page => 2
        result.total_pages.should == 1
        result.should be_empty
      }.should run_queries(2)
    end
    
    it "should paginate with :order" do
      result = Topic.paginate :page => 1, :order => 'created_at DESC'
      result.should == topics(:futurama, :harvey_birdman, :rails, :ar).reverse
      result.total_pages.should == 1
    end
    
    it "should paginate with :conditions" do
      result = Topic.paginate :page => 1, :conditions => ["created_at > ?", 30.minutes.ago]
      result.should == topics(:rails, :ar)
      result.total_pages.should == 1
    end

    it "should paginate with :include and :conditions" do
      result = Topic.paginate \
        :page     => 1, 
        :include  => :replies,  
        :conditions => "replies.content LIKE 'Bird%' ", 
        :per_page => 10

      expected = Topic.find :all, 
        :include => 'replies', 
        :conditions => "replies.content LIKE 'Bird%' ", 
        :limit   => 10

      result.should == expected
      result.total_entries.should == 1
    end

    it "should paginate with :include and :order" do
      result = nil
      lambda {
        result = Topic.paginate \
          :page     => 1, 
          :include  => :replies,  
          :order    => 'replies.created_at asc, topics.created_at asc', 
          :per_page => 10
      }.should run_queries(2)

      expected = Topic.find :all, 
        :include => 'replies', 
        :order   => 'replies.created_at asc, topics.created_at asc', 
        :limit   => 10

      result.should == expected
      result.total_entries.should == 4
    end
    
    # detect ActiveRecord 2.1
    if ActiveRecord::Base.private_methods.include?('references_eager_loaded_tables?')
      it "should remove :include for count" do
        Developer.expects(:find).returns([1])
        Developer.expects(:count).with({}).returns(0)
    
        Developer.paginate :page => 1, :per_page => 1, :include => :projects
      end
    
      it "should keep :include for count when they are referenced in :conditions" do
        Developer.expects(:find).returns([1])
        Developer.expects(:count).with({ :include => :projects, :conditions => 'projects.id > 2' }).returns(0)
    
        Developer.paginate :page => 1, :per_page => 1,
          :include => :projects, :conditions => 'projects.id > 2'
      end
    end
    
    describe "associations" do
      it "should paginate with include" do
        project = projects(:active_record)

        result = project.topics.paginate \
          :page       => 1, 
          :include    => :replies,  
          :conditions => ["replies.content LIKE ?", 'Nice%'],
          :per_page   => 10

        expected = Topic.find :all, 
          :include    => 'replies', 
          :conditions => ["project_id = #{project.id} AND replies.content LIKE ?", 'Nice%'],
          :limit      => 10

        result.should == expected
      end

      it "should paginate" do
        dhh = users(:david)
        expected_name_ordered = projects(:action_controller, :active_record)
        expected_id_ordered   = projects(:active_record, :action_controller)

        lambda {
          # with association-specified order
          result = dhh.projects.paginate(:page => 1)
          result.should == expected_name_ordered
          result.total_entries.should == 2
        }.should run_queries(2)

        # with explicit order
        result = dhh.projects.paginate(:page => 1, :order => 'projects.id')
        result.should == expected_id_ordered
        result.total_entries.should == 2

        lambda {
          dhh.projects.find(:all, :order => 'projects.id', :limit => 4)
        }.should_not raise_error
        
        result = dhh.projects.paginate(:page => 1, :order => 'projects.id', :per_page => 4)
        result.should == expected_id_ordered

        # has_many with implicit order
        topic = Topic.find(1)
        expected = replies(:spam, :witty_retort)
        # FIXME: wow, this is ugly
        topic.replies.paginate(:page => 1).map(&:id).sort.should == expected.map(&:id).sort
        topic.replies.paginate(:page => 1, :order => 'replies.id ASC').should == expected.reverse
      end

      it "should paginate through association extension" do
        project = Project.find(:first)
        expected = [replies(:brave)]

        lambda {
          result = project.replies.paginate_recent :page => 1
          result.should == expected
        }.should run_queries(1)
      end
    end
    
    it "should paginate with joins" do
      result = nil
      join_sql = 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id'

      lambda {
        result = Developer.paginate :page => 1, :joins => join_sql, :conditions => 'project_id = 1'
        result.size.should == 2
        developer_names = result.map(&:name)
        developer_names.should include('David')
        developer_names.should include('Jamis')
      }.should run_queries(1)

      lambda {
        expected = result.to_a
        result = Developer.paginate :page => 1, :joins => join_sql,
                             :conditions => 'project_id = 1', :count => { :select => "users.id" }
        result.should == expected
        result.total_entries.should == 2
      }.should run_queries(1)
    end

    it "should paginate with group" do
      result = nil
      lambda {
        result = Developer.paginate :page => 1, :per_page => 10,
                                    :group => 'salary', :select => 'salary', :order => 'salary'
      }.should run_queries(1)

      expected = users(:david, :jamis, :dev_10, :poor_jamis).map(&:salary).sort
      result.map(&:salary).should == expected
    end

    it "should paginate with dynamic finder" do
      expected = replies(:witty_retort, :spam)
      Reply.paginate_by_topic_id(1, :page => 1).should == expected

      result = Developer.paginate :conditions => { :salary => 100000 }, :page => 1, :per_page => 5
      result.total_entries.should == 8
      Developer.paginate_by_salary(100000, :page => 1, :per_page => 5).should == result
    end

    it "should paginate with dynamic finder and conditions" do
      result = Developer.paginate_by_salary(100000, :page => 1, :conditions => ['id > ?', 6])
      result.total_entries.should == 4
      result.map(&:id).should == (7..10).to_a
    end

    it "should raise error when dynamic finder is not recognized" do
      lambda {
        Developer.paginate_by_inexistent_attribute 100000, :page => 1
      }.should raise_error(NoMethodError)
    end

    it "should paginate with_scope" do
      result = Developer.with_poor_ones { Developer.paginate :page => 1 }
      result.size.should == 2
      result.total_entries.should == 2
    end

    describe "named_scope" do
      it "should paginate" do
        result = Developer.poor.paginate :page => 1, :per_page => 1
        result.size.should == 1
        result.total_entries.should == 2
      end

      it "should paginate on habtm association" do
        project = projects(:active_record)
        lambda {
          result = project.developers.poor.paginate :page => 1, :per_page => 1
          result.size.should == 1
          result.total_entries.should == 1
        }.should run_queries(2)
      end

      it "should paginate on hmt association" do
        project = projects(:active_record)
        expected = [replies(:brave)]

        lambda {
          result = project.replies.recent.paginate :page => 1, :per_page => 1
          result.should == expected
          result.total_entries.should == 1
        }.should run_queries(2)
      end

      it "should paginate on has_many association" do
        project = projects(:active_record)
        expected = [topics(:ar)]

        lambda {
          result = project.topics.mentions_activerecord.paginate :page => 1, :per_page => 1
          result.should == expected
          result.total_entries.should == 1
        }.should run_queries(2)
      end
    end

    it "should paginate with :readonly option" do
      lambda { Developer.paginate :readonly => true, :page => 1 }.should_not raise_error
    end
    
    # detect ActiveRecord 2.0
    unless ActiveRecord::Base.respond_to? :find_all
      it "should paginate array of IDs" do
        # AR finders also accept arrays of IDs
        # (this was broken in Rails before [6912])
        lambda {
          result = Developer.paginate((1..8).to_a, :per_page => 3, :page => 2, :order => 'id')
          result.map(&:id).should == (4..6).to_a
          result.total_entries.should == 8
        }.should run_queries(1)
      end
    end
    
  end
  
  protected
  
    def run_queries(num)
      QueryCountMatcher.new(num)
    end

end

class QueryCountMatcher
  def initialize(num)
    @queries = num
    @old_query_count = $query_count
  end

  def matches?(block)
    block.call
    @queries_run = $query_count - @old_query_count
    @queries == @queries_run
  end

  def failure_message
    "expected #{@queries} queries, got #{@queries_run}"
  end

  def negative_failure_message
    "expected query count not to be #{$queries}"
  end
end