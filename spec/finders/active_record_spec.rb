require 'spec_helper'
require 'will_paginate/active_record'
require File.expand_path('../activerecord_test_connector', __FILE__)

ActiverecordTestConnector.setup

RSpec.describe WillPaginate::ActiveRecord do

  extend ActiverecordTestConnector::FixtureSetup

  fixtures :topics, :replies, :users, :projects, :developers_projects

  it "should integrate with ActiveRecord::Base" do
    expect(ActiveRecord::Base).to respond_to(:paginate)
  end

  it "should paginate" do
    expect {
      users = User.paginate(:page => 1, :per_page => 5).to_a
      expect(users.length).to eq(5)
    }.to execute(2).queries
  end

  it "should fail when encountering unknown params" do
    expect {
      User.paginate :foo => 'bar', :page => 1, :per_page => 4
    }.to raise_error(ArgumentError)
  end

  describe "relation" do
    it "should return a relation" do
      rel = nil
      expect {
        rel = Developer.paginate(:page => 1)
        expect(rel.per_page).to eq(10)
        expect(rel.current_page).to eq(1)
      }.to execute(0).queries

      expect {
        expect(rel.total_pages).to eq(2)
      }.to execute(1).queries
    end

    it "should keep per-class per_page number" do
      rel = Developer.order('id').paginate(:page => 1)
      expect(rel.per_page).to eq(10)
    end

    it "should be able to change per_page number" do
      rel = Developer.order('id').paginate(:page => 1).limit(5)
      expect(rel.per_page).to eq(5)
    end

    it "remembers pagination in sub-relations" do
      rel = Topic.paginate(:page => 2, :per_page => 3)
      expect {
        expect(rel.total_entries).to eq(4)
      }.to execute(1).queries
      rel = rel.mentions_activerecord
      expect(rel.current_page).to eq(2)
      expect(rel.per_page).to eq(3)
      expect {
        expect(rel.total_entries).to eq(1)
      }.to execute(1).queries
    end

    it "supports the page() method" do
      rel = Developer.page('1').order('id')
      expect(rel.current_page).to eq(1)
      expect(rel.per_page).to eq(10)
      expect(rel.offset).to eq(0)

      rel = rel.limit(5).page(2)
      expect(rel.per_page).to eq(5)
      expect(rel.offset).to eq(5)
    end

    it "raises on invalid page number" do
      expect {
        Developer.page('foo')
      }.to raise_error(ArgumentError)
    end

    it "supports first limit() then page()" do
      rel = Developer.limit(3).page(3)
      expect(rel.offset).to eq(6)
    end

    it "supports first page() then limit()" do
      rel = Developer.page(3).limit(3)
      expect(rel.offset).to eq(6)
    end

    it "supports #first" do
      rel = Developer.order('id').page(2).per_page(4)
      expect(rel.first).to eq(users(:dev_5))
      expect(rel.first(2)).to eq(users(:dev_5, :dev_6))
    end

    it "supports #last" do
      rel = Developer.order('id').page(2).per_page(4)
      expect(rel.last).to eq(users(:dev_8))
      expect(rel.last(2)).to eq(users(:dev_7, :dev_8))
      expect(rel.page(3).last).to eq(users(:poor_jamis))
    end
  end

  describe "counting" do
    it "should guess the total count" do
      expect {
        topics = Topic.paginate :page => 2, :per_page => 3
        expect(topics.total_entries).to eq(4)
      }.to execute(1).queries
    end

    it "should guess that there are no records" do
      expect {
        topics = Topic.where(:project_id => 999).paginate :page => 1, :per_page => 3
        expect(topics.total_entries).to eq(0)
      }.to execute(1).queries
    end

    it "forgets count in sub-relations" do
      expect {
        topics = Topic.paginate :page => 1, :per_page => 3
        expect(topics.total_entries).to eq(4)
        expect(topics.where('1 = 1').total_entries).to eq(4)
      }.to execute(2).queries
    end

    it "supports empty? method" do
      topics = Topic.paginate :page => 1, :per_page => 3
      expect {
        expect(topics).not_to be_empty
      }.to execute(1).queries
    end

    it "support empty? for grouped queries" do
      topics = Topic.group(:project_id).paginate :page => 1, :per_page => 3
      expect {
        expect(topics).not_to be_empty
      }.to execute(1).queries
    end

    it "supports `size` for grouped queries" do
      topics = Topic.group(:project_id).paginate :page => 1, :per_page => 3
      expect {
        expect(topics.size).to eq({nil=>2, 1=>2})
      }.to execute(1).queries
    end

    it "overrides total_entries count with a fixed value" do
      expect {
        topics = Topic.paginate :page => 1, :per_page => 3, :total_entries => 999
        expect(topics.total_entries).to eq(999)
        # value is kept even in sub-relations
        expect(topics.where('1 = 1').total_entries).to eq(999)
      }.to execute(0).queries
    end

    it "supports a non-int for total_entries" do
      topics = Topic.paginate :page => 1, :per_page => 3, :total_entries => "999"
      expect(topics.total_entries).to eq(999)
    end

    it "overrides empty? count call with a total_entries fixed value" do
      expect {
        topics = Topic.paginate :page => 1, :per_page => 3, :total_entries => 999
        expect(topics).not_to be_empty
      }.to execute(0).queries
    end

    it "removes :include for count" do
      expect {
        developers = Developer.paginate(:page => 1, :per_page => 1).includes(:projects)
        expect(developers.total_entries).to eq(11)
        expect($query_sql.last).not_to match(/\bJOIN\b/)
      }.to execute(1).queries
    end

    it "keeps :include for count when they are referenced in :conditions" do
      developers = Developer.paginate(:page => 1, :per_page => 1).includes(:projects)
      with_condition = developers.where('projects.id > 1')
      with_condition = with_condition.references(:projects) if with_condition.respond_to?(:references)
      expect(with_condition.total_entries).to eq(1)

      expect($query_sql.last).to match(/\bJOIN\b/)
    end

    it "should count with group" do
      expect(Developer.group(:salary).page(1).total_entries).to eq(4)
    end

    it "should count with select" do
      expect(Topic.select('title, content').page(1).total_entries).to eq(4)
    end

    it "removes :reorder for count with group" do
      Project.group(:id).reorder(:id).page(1).total_entries
      expect($query_sql.last).not_to match(/\ORDER\b/)
    end

    it "should not have zero total_pages when the result set is empty" do
      expect(Developer.where("1 = 2").page(1).total_pages).to eq(1)
    end

    it "should calculate total_pages after calling merge with unscoped limit" do
      expect {
        paginated_projects = Project.all.paginate(:page => 1, :per_page => 3)
        unscoped_activerecord_topics = Topic.mentions_activerecord.unscope(:limit)
        result = paginated_projects.joins(:topics).merge(unscoped_activerecord_topics)
        expect(result.total_pages).to eq(1)
      }.not_to raise_error
    end
  end

  it "should not ignore :select parameter when it says DISTINCT" do
    users = User.select('DISTINCT salary').paginate :page => 2
    expect(users.total_entries).to eq(5)
  end

  describe "paginate_by_sql" do
    it "should respond" do
      expect(User).to respond_to(:paginate_by_sql)
    end

    it "should paginate" do
      expect {
        sql = "select content from topics where content like '%futurama%'"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 1
        expect(topics.total_entries).to eq(1)
        expect(topics.first.attributes.has_key?('title')).to be(false)
      }.to execute(2).queries
    end

    it "should respect total_entries setting" do
      expect {
        sql = "select content from topics"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 1, :total_entries => 999
        expect(topics.total_entries).to eq(999)
      }.to execute(1).queries
    end

    it "defaults to page 1" do
      sql = "select content from topics"
      topics = Topic.paginate_by_sql sql, :page => nil, :per_page => 1
      expect(topics.current_page).to eq(1)
      expect(topics.size).to eq(1)
    end

    it "should strip the order when counting" do
      expected = topics(:ar)
      expect {
        sql = "select id, title, content from topics order by topics.title"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 2
        expect(topics.first).to eq(expected)
      }.to execute(2).queries

      expect($query_sql.last).to include('COUNT')
      expect($query_sql.last).not_to include('order by topics.title')
    end

    it "shouldn't change the original query string" do
      query = 'select * from topics where 1 = 2'
      original_query = query.dup
      Topic.paginate_by_sql(query, :page => 1)
      expect(query).to eq(original_query)
    end
  end

  it "doesn't mangle options" do
    options = { :page => 1 }
    options.expects(:delete).never
    options_before = options.dup

    Topic.paginate(options)
    expect(options).to eq(options_before)
  end

  it "should get first page of Topics with a single query" do
    expect {
      result = Topic.paginate :page => nil
      result.to_a # trigger loading of records
      expect(result.current_page).to eq(1)
      expect(result.total_pages).to eq(1)
      expect(result.size).to eq(4)
    }.to execute(1).queries
  end

  it "should get second (inexistent) page of Topics, requiring 1 query" do
    expect {
      result = Topic.paginate :page => 2
      expect(result.total_pages).to eq(1)
      expect(result).to be_empty
    }.to execute(1).queries
  end

  describe "associations" do
    it "should paginate" do
      dhh = users(:david)
      expected_name_ordered = projects(:action_controller, :active_record)
      expected_id_ordered   = projects(:active_record, :action_controller)

      expect {
        # with association-specified order
        result = ignore_deprecation {
          dhh.projects.includes(:topics).order('projects.name').paginate(:page => 1)
        }
        expect(result.to_a).to eq(expected_name_ordered)
        expect(result.total_entries).to eq(2)
      }.to execute(2).queries

      # with explicit order
      result = dhh.projects.paginate(:page => 1).reorder('projects.id')
      expect(result).to eq(expected_id_ordered)
      expect(result.total_entries).to eq(2)

      expect {
        dhh.projects.order('projects.id').limit(4).to_a
      }.not_to raise_error

      result = dhh.projects.paginate(:page => 1, :per_page => 4).reorder('projects.id')
      expect(result).to eq(expected_id_ordered)

      # has_many with implicit order
      topic = Topic.find(1)
      expected = replies(:spam, :witty_retort)
      # FIXME: wow, this is ugly
      expect(topic.replies.paginate(:page => 1).map(&:id).sort).to eq(expected.map(&:id).sort)
      expect(topic.replies.paginate(:page => 1).reorder('replies.id ASC')).to eq(expected.reverse)
    end

    it "should paginate through association extension" do
      project = Project.order('id').first
      expected = [replies(:brave)]

      expect {
        result = project.replies.only_recent.paginate(:page => 1)
        expect(result).to eq(expected)
      }.to execute(1).queries
    end
  end

  it "should paginate with joins" do
    result = nil
    join_sql = 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id'

    expect {
      result = Developer.where('developers_projects.project_id = 1').joins(join_sql).paginate(:page => 1)
      result.to_a # trigger loading of records
      expect(result.size).to eq(2)
      developer_names = result.map(&:name)
      expect(developer_names).to include('David')
      expect(developer_names).to include('Jamis')
    }.to execute(1).queries

    expect {
      expected = result.to_a
      result = Developer.where('developers_projects.project_id = 1').joins(join_sql).paginate(:page => 1)
      expect(result).to eq(expected)
      expect(result.total_entries).to eq(2)
    }.to execute(1).queries
  end

  it "should paginate with group" do
    result = nil
    expect {
      result = Developer.select('salary').order('salary').group('salary').
        paginate(:page => 1, :per_page => 10).to_a
    }.to execute(1).queries

    expected = users(:david, :jamis, :dev_10, :poor_jamis).map(&:salary).sort
    expect(result.map(&:salary)).to eq(expected)
  end

  it "should not paginate with dynamic finder" do
    expect {
      Developer.paginate_by_salary(100000, :page => 1, :per_page => 5)
    }.to raise_error(NoMethodError)
  end

  describe "scopes" do
    it "should paginate" do
      result = Developer.poor.paginate :page => 1, :per_page => 1
      expect(result.size).to eq(1)
      expect(result.total_entries).to eq(2)
    end

    it "should paginate on habtm association" do
      project = projects(:active_record)
      expect {
        result = ignore_deprecation { project.developers.poor.paginate :page => 1, :per_page => 1 }
        expect(result.size).to eq(1)
        expect(result.total_entries).to eq(1)
      }.to execute(2).queries
    end

    it "should paginate on hmt association" do
      project = projects(:active_record)
      expected = [replies(:brave)]

      expect {
        result = project.replies.recent.paginate :page => 1, :per_page => 1
        expect(result).to eq(expected)
        expect(result.total_entries).to eq(1)
      }.to execute(2).queries
    end

    it "should paginate on has_many association" do
      project = projects(:active_record)
      expected = [topics(:ar)]

      expect {
        result = project.topics.mentions_activerecord.paginate :page => 1, :per_page => 1
        expect(result).to eq(expected)
        expect(result.total_entries).to eq(1)
      }.to execute(2).queries
    end
  end

  it "should not paginate an array of IDs" do
    expect {
      Developer.paginate((1..8).to_a, :per_page => 3, :page => 2, :order => 'id')
    }.to raise_error(ArgumentError)
  end

  it "errors out for invalid values" do |variable|
    expect {
      # page that results in an offset larger than BIGINT
      Project.page(307445734561825862)
    }.to raise_error(WillPaginate::InvalidPage, "invalid offset: 9223372036854775830")
  end
 end
