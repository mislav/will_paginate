require 'helper'
require 'lib/view_test_process'

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
  
  def test_complex_custom_page_param
    get :list_developers, { :developers => {:page => 1} }, :wp => { :param_name => 'developers[page]' }
    entries = assigns :developers
    
    assert_links_match /\?developers%5Bpage%5D=\d+$/

    assert_select 'div.pagination', 1, 'no main DIV' do
      assert_select 'a[href]', 3 do |elements|
        validate_page_numbers [2,3,2], elements, 'developers[page]'
      end
      assert_select 'span.current', entries.current_page.to_s
    end    
  end
  
protected

  def validate_page_numbers expected, links, param_name = :page
    param_pattern = /\W#{CGI.escape(param_name.to_s)}=([^&]*)/
    
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
