require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class PaginationTest < ActiveRecordTestCase
  fixtures :developers
  
  class PaginationController < ActionController::Base
    
    def list_developers
      @developers = Developer.paginate :page => params[:page], :per_page => (params[:per_page] || 4).to_i

      options = [:class, :prev_label, :next_label, :inner_window, :outer_window]
      @options = params.slice(*options)
      options.each { |key| params.delete key }

      render :inline => '<%= will_paginate @developers, @options %>'
    end

    def no_pagination
      @developers = Developer.paginate :page => params[:page], :per_page => 15

      render :inline => '<%= will_paginate @developers %>'
    end

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

  def test_will_paginate_windows
    get :list_developers, :page => 6, :per_page => 1, :inner_window => 2
    assert_response :success
    
    entries = assigns :developers
    assert entries
    assert_equal 1, entries.size

    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 10 do |elements|
        assert_equal [5,1,2,4,5,7,8,10,11,7], elements.map{|e| e['href'] =~ /page=(\d+)/; $1.to_i }
        assert_select elements.first, 'a', "&laquo; Previous"
        assert_select elements.last, 'a', "Next &raquo;"
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

end
