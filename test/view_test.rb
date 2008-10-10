require 'helper'
require 'lib/view_test_process'

class ViewTest < WillPaginate::ViewTestCase
  
  ## parameter handling in page links ##
  
  def test_will_paginate_preserves_parameters_on_get
    @request.params :foo => { :bar => 'baz' }
    paginate
    assert_links_match /foo%5Bbar%5D=baz/
  end
  
  def test_will_paginate_doesnt_preserve_parameters_on_post
    @request.post
    @request.params :foo => 'bar'
    paginate
    assert_no_links_match /foo=bar/
  end
  
  def test_adding_additional_parameters
    paginate({}, :params => { :foo => 'bar' })
    assert_links_match /foo=bar/
  end
  
  def test_adding_anchor_parameter
    paginate({}, :params => { :anchor => 'anchor' })
    assert_links_match /#anchor$/
  end
  
  def test_removing_arbitrary_parameters
    @request.params :foo => 'bar'
    paginate({}, :params => { :foo => nil })
    assert_no_links_match /foo=bar/
  end
    
  def test_adding_additional_route_parameters
    paginate({}, :params => { :controller => 'baz', :action => 'list' })
    assert_links_match %r{\Wbaz/list\W}
  end
  
  def test_will_paginate_with_custom_page_param
    paginate({ :page => 2 }, :param_name => :developers_page) do
      assert_select 'a[href]', 4 do |elements|
        validate_page_numbers [1,1,3,3], elements, :developers_page
      end
    end    
  end
  
  def test_complex_custom_page_param
    @request.params :developers => { :page => 2 }
    
    paginate({ :page => 2 }, :param_name => 'developers[page]') do
      assert_select 'a[href]', 4 do |links|
        assert_links_match /\?developers%5Bpage%5D=\d+$/, links
        validate_page_numbers [1,1,3,3], links, 'developers[page]'
      end
    end
  end

  def test_custom_routing_page_param
    @request.symbolized_path_parameters.update :controller => 'dummy', :action => nil
    paginate :per_page => 2 do
      assert_select 'a[href]', 6 do |links|
        assert_links_match %r{/page/(\d+)$}, links, [2, 3, 4, 5, 6, 2]
      end
    end
  end

  def test_custom_routing_page_param_with_dot_separator
    @request.symbolized_path_parameters.update :controller => 'dummy', :action => 'dots'
    paginate :per_page => 2 do
      assert_select 'a[href]', 6 do |links|
        assert_links_match %r{/page\.(\d+)$}, links, [2, 3, 4, 5, 6, 2]
      end
    end
  end

  def test_custom_routing_with_first_page_hidden
    @request.symbolized_path_parameters.update :controller => 'ibocorp', :action => nil
    paginate :page => 2, :per_page => 2 do
      assert_select 'a[href]', 7 do |links|
        assert_links_match %r{/ibocorp(?:/(\d+))?$}, links, [nil, nil, 3, 4, 5, 6, 3]
      end
    end
  end

  ## internal hardcore stuff ##

  uses_mocha 'view internals' do
    def test_collection_name_can_be_guessed
      collection = mock
      collection.expects(:total_pages).returns(1)
      
      @template = '<%= will_paginate options %>'
      @controller.controller_name = 'developers'
      @view.assigns['developers'] = collection
      
      paginate(nil)
    end
  end
  
  def test_inferred_collection_name_raises_error_when_nil
    @template = '<%= will_paginate options %>'
    @controller.controller_name = 'developers'
    
    e = assert_raise ArgumentError do
      paginate(nil)
    end
    assert e.message.include?('@developers')
  end

  if ActionController::Base.respond_to? :rescue_responses
    # only on Rails 2
    def test_rescue_response_hook_presence
      assert_equal :not_found,
        ActionController::Base.rescue_responses['WillPaginate::InvalidPage']
    end
  end
  
end
