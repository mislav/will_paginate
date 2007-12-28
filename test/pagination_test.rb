require File.dirname(__FILE__) + '/helper'
require 'action_controller'
require 'action_controller/test_process'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

ActionController::Base.perform_caching = false

require 'will_paginate'
WillPaginate.enable_actionpack

class PaginationTest < Test::Unit::TestCase
  
  class DevelopersController < ActionController::Base
    def list_developers
      @options = session[:wp] || {}
      
      @developers = (1..11).to_a.paginate(
        :page => params[@options[:param_name] || :page] || 1,
        :per_page => params[:per_page] || 4
      )

      render :inline => '<%= will_paginate @developers, @options %>'
    end

    def guess_collection_name
      @developers = session[:wp]
      @options    = session[:wp_options]
      render :inline => '<%= will_paginate @options %>'
    end

    protected
      def rescue_errors(e) raise e end
      def rescue_action(e) raise e end
  end
  
  def setup
    @controller = DevelopersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def test_will_paginate
    get :list_developers

    entries = assigns :developers
    assert entries
    assert_equal 4, entries.size

    assert_select 'div.pagination', 1, 'no main DIV' do |el|
      assert_select 'a[href]', 3 do |elements|
        validate_page_numbers [2,3,2], elements
        assert_select elements.last, ':last-child', "Next &raquo;"
      end
      assert_select 'span', 2
      assert_select 'span.disabled:first-child', "&laquo; Previous"
      assert_select 'span.current', entries.current_page.to_s
    end
  end

  def test_will_paginate_with_options
    get :list_developers, { :page => 2 }, :wp => {
      :class => 'will_paginate', :prev_label => 'Prev', :next_label => 'Next'
    }
    assert_response :success
    
    entries = assigns :developers
    assert entries
    assert_equal 4, entries.size

    assert_select 'div.will_paginate', 1, 'no main DIV' do
      assert_select 'a[href]', 4 do |elements|
        validate_page_numbers [1,1,3,3], elements
        assert_select elements.first, 'a', "Prev"
        assert_select elements.last, 'a', "Next"
      end
      assert_select 'span.current', entries.current_page.to_s
    end
  end

  def test_will_paginate_without_container
    get :list_developers, {}, :wp => { :container => false }
    assert_select 'div.pagination', 0, 'no main DIV'
    assert_select 'a[href]', 3
  end

  def test_will_paginate_without_page_links
    get :list_developers, { :page => 2 }, :wp => { :page_links => false }
    assert_select 'a[href]', 2 do |elements|
      validate_page_numbers [1,3], elements
    end
  end
  
  def test_will_paginate_preserves_parameters_on_get
    get :list_developers, :foo => { :bar => 'baz' }
    assert_links_match /foo%5Bbar%5D=baz/
  end
  
  def test_will_paginate_doesnt_preserve_parameters_on_post
    post :list_developers, :foo => 'bar'
    assert_no_links_match /foo=bar/
  end
  
  def test_adding_additional_parameters
    get :list_developers, {}, :wp => { :params => { :foo => 'bar' } }
    assert_links_match /foo=bar/
  end
  
  def test_removing_arbitrary_parameters
    get :list_developers, { :foo => 'bar' }, :wp => { :params => { :foo => nil } }
    assert_no_links_match /foo=bar/
  end
    
  def test_adding_additional_route_parameters
    get :list_developers, {}, :wp => { :params => { :controller => 'baz' } }
    assert_links_match %r{\Wbaz/list_developers\W}
  end
  
  def test_will_paginate_with_custom_page_param
    get :list_developers, { :developers_page => 2 }, :wp => { :param_name => :developers_page }
    assert_response :success
    
    entries = assigns :developers
    assert entries
    assert_equal 4, entries.size

    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 4 do |elements|
        validate_page_numbers [1,1,3,3], elements, :developers_page
      end
      assert_select 'span.current', entries.current_page.to_s
    end    
  end

  def test_will_paginate_windows
    get :list_developers, { :page => 6, :per_page => 1 }, :wp => { :inner_window => 1 }
    assert_response :success
    
    entries = assigns :developers
    assert entries
    assert_equal 1, entries.size

    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 8 do |elements|
        validate_page_numbers [5,1,2,5,7,10,11,7], elements
        assert_select elements.first, 'a', "&laquo; Previous"
        assert_select elements.last, 'a', "Next &raquo;"
      end
      assert_select 'span.current', entries.current_page.to_s
    end
  end

  def test_will_paginate_eliminates_small_gaps
    get :list_developers, { :page => 6, :per_page => 1 }, :wp => { :inner_window => 2 }
    assert_response :success
    
    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 12 do |elements|
        validate_page_numbers [5,1,2,3,4,5,7,8,9,10,11,7], elements
      end
    end
  end

  def test_no_pagination
    get :list_developers, :per_page => 12
    entries = assigns :developers
    assert_equal 1, entries.page_count
    assert_equal 11, entries.size

    assert_equal '', @response.body
  end
  
  def test_faulty_input_raises_error
    assert_raise WillPaginate::InvalidPage do
      get :list_developers, :page => 'foo'
    end
  end

  uses_mocha 'helper internals' do
    def test_collection_name_can_be_guessed
      collection = mock
      collection.expects(:page_count).returns(1)
      get :guess_collection_name, {}, :wp => collection
    end
  end
  
  def test_inferred_collection_name_raises_error_when_nil
    ex = assert_raise ArgumentError do
      get :guess_collection_name, {}, :wp => nil
    end
    assert ex.message.include?('@developers')
  end

  def test_setting_id_for_container
    get :list_developers
    assert_select 'div.pagination', 1 do |div|
      assert_nil div.first['id']
    end
    # magic ID
    get :list_developers, {}, :wp => { :id => true }
    assert_select 'div.pagination', 1 do |div|
      assert_equal 'fixnums_pagination', div.first['id']
    end
    # explicit ID
    get :list_developers, {}, :wp => { :id => 'custom_id' }
    assert_select 'div.pagination', 1 do |div|
      assert_equal 'custom_id', div.first['id']
    end
  end
  
protected

  def validate_page_numbers expected, links, param_name = :page
    param_pattern = /\W#{param_name}=([^&]*)/
    
    assert_equal(expected, links.map { |e|
      e['href'] =~ param_pattern
      $1 ? $1.to_i : $1
    })
  end

  def assert_links_match pattern
    assert_select 'div.pagination a[href]' do |elements|
      elements.each do |el|
        assert_match pattern, el['href']
      end
    end
  end

  def assert_no_links_match pattern
    assert_select 'div.pagination a[href]' do |elements|
      elements.each do |el|
        assert_no_match pattern, el['href']
      end
    end
  end
end
