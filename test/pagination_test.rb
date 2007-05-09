require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class PaginationTest < ActiveRecordTestCase
  fixtures :developers
  
  class PaginationController < ActionController::Base
    
    def list_developers
      @developers = Developer.paginate :page => params[:page], :per_page => 4
      @options = params.slice(:class, :prev_label, :next_label)
      @options.keys.each { |key| params.delete key }

      render :inline => '<%= will_paginate @developers, @options %>'
    end

    def no_pagination
      @developers = Developer.paginate :page => params[:page], :per_page => 15

      render :inline => '<%= will_paginate @developers %>'
    end

    # This functionality is removed. There may be something similar in the future,
    # so I'm keeping this
    #
    # def simple_paginate
    #   @topic_pages, @topics = paginate(:topics)
    #   render :nothing => true
    # end
    # 
    # def paginate_with_class_name
    #   @developer_pages, @developers = paginate(:developers, :class_name => "DeVeLoPeR")
    #   render :nothing => true
    # end
    # 
    # def paginate_with_singular_name
    #   @developer_pages, @developers = paginate(:ninjas, :singular_name => 'developer')
    #   render :nothing => true
    # end
    # 
    # def paginate_with_join
    #   @developer_pages, @developers = paginate(:developers, 
    #                                            :joins => 'LEFT JOIN developers_projects ON developers.id = developers_projects.developer_id',
    #                                            :conditions => 'project_id=1')        
    #   render :nothing => true
    # end
    # 
    # def paginate_with_join_and_count
    #   @developer_pages, @developers = paginate(:developers, 
    #                                            :joins => 'd LEFT JOIN developers_projects ON d.id = developers_projects.developer_id',
    #                                            :conditions => 'project_id=1',
    #                                            :count => "d.id")        
    #   render :nothing => true
    # end

  protected

    def rescue_errors(e) raise e end
    def rescue_action(e) raise e end
  end
  
  def setup
    @controller = PaginationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def test_will_paginate
    get :list_developers

    entries = assigns :developers
    assert entries
    assert_equal 4, entries.size

    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 3 do |elements|
        assert_equal [2,3,2], elements.map{|e| e['href'] =~ /page=(\d+)/; $1.to_i }
        assert_select elements.last, ':last-child', "Next &raquo;"
      end
      assert_select 'span', 2
      assert_select 'span.disabled:first-child', "&laquo; Previous"
      assert_select 'span.current', entries.current_page.to_s
    end
  end

  def test_will_paginate_with_options
    get :list_developers, :page => 2, :class => 'will_paginate', :prev_label => 'Prev', :next_label => 'Next'
    assert_response :success
    
    entries = assigns :developers
    assert entries
    assert_equal 4, entries.size

    assert_select 'div.will_paginate', 1, 'no main DIV' do
      assert_select 'a[href]', 4 do |elements|
        assert_equal [1,1,3,3], elements.map{|e| e['href'] =~ /page=(\d+)/; $1.to_i }
        assert_select elements.first, 'a', "Prev"
        assert_select elements.last, 'a', "Next"
      end
      assert_select 'span.current', entries.current_page.to_s
    end
  end

  def test_no_pagination
    get :no_pagination
    entries = assigns :developers
    assert_equal 1, entries.page_count
    assert_equal Developer.count, entries.size

    assert_select 'div', false
    assert_equal '', @response.body
  end

  # def test_simple_paginate
  #   get :simple_paginate
  #   assert_equal 1, assigns(:topic_pages).page_count
  #   assert_equal 3, assigns(:topics).size
  # end
  # 
  # def test_paginate_with_explicit_names
  #   get :paginate_with_class_name
  #   expected = assigns(:developers)
  #   assert expected.size > 0
  #   assert_equal DeVeLoPeR, expected.first.class
  # 
  #   get :paginate_with_singular_name
  #   assert_equal expected.size, assigns(:developers).size
  # end
  #     
  # def test_paginate_with_join_and_count
  #   get :paginate_with_join
  #   expected = assigns(:developers)
  #   assert expected
  #   get :paginate_with_join_and_count
  #   assert_equal expected, assigns(:developers)
  # end
end
