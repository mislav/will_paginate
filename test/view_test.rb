require 'helper'
require 'action_controller'
require 'lib/view_test_process'

class ViewTest < Test::Unit::TestCase
  
  def setup
    super
    @controller  = DummyController.new
    @request     = @controller.request
    @html_result = nil
    @template    = '<%= will_paginate collection, options %>'
    
    @view = ActionView::Base.new
    @view.assigns['controller'] = @controller
    @view.assigns['_request']   = @request
    @view.assigns['_params']    = @request.params
  end

  ## basic pagination ##

  def test_will_paginate
    paginate do |pagination|
      assert_select 'a[href]', 3 do |elements|
        validate_page_numbers [2,3,2], elements
        assert_select elements.last, ':last-child', "Next &raquo;"
      end
      assert_select 'span', 2
      assert_select 'span.disabled:first-child', '&laquo; Previous'
      assert_select 'span.current', '1'
      assert_equal '&laquo; Previous 1 2 3 Next &raquo;', pagination.first.inner_text
    end
  end

  def test_no_pagination_when_page_count_is_one
    paginate :per_page => 30
    assert_equal '', @html_result
  end

  def test_will_paginate_with_options
    paginate({ :page => 2 },
             :class => 'will_paginate', :prev_label => 'Prev', :next_label => 'Next') do
      assert_select 'a[href]', 4 do |elements|
        validate_page_numbers [1,1,3,3], elements
        # test rel attribute values:
        assert_select elements[1], 'a', '1' do |link|
          assert_equal 'prev start', link.first['rel']
        end
        assert_select elements.first, 'a', "Prev" do |link|
          assert_equal 'prev start', link.first['rel']
        end
        assert_select elements.last, 'a', "Next" do |link|
          assert_equal 'next', link.first['rel']
        end
      end
      assert_select 'span.current', '2'
    end
  end

  def test_prev_next_links_have_classnames
    paginate do |pagination|
      assert_select 'span.disabled.prev_page:first-child'
      assert_select 'a.next_page[href]:last-child'
    end
  end

  def test_full_output
    paginate
    expected = <<-HTML
      <div class="pagination"><span class="disabled prev_page">&laquo; Previous</span>
      <span class="current">1</span>
      <a href="/foo/bar?page=2" rel="next">2</a>
      <a href="/foo/bar?page=3">3</a>
      <a href="/foo/bar?page=2" class="next_page" rel="next">Next &raquo;</a></div>
    HTML
    expected.strip!.gsub!(/\s{2,}/, ' ')
    
    assert_dom_equal expected, @html_result
  end

  ## advanced options for pagination ##

  def test_will_paginate_without_container
    paginate({}, :container => false)
    assert_select 'div.pagination', 0, 'main DIV present when it shouldn\'t'
    assert_select 'a[href]', 3
  end

  def test_will_paginate_without_page_links
    paginate({ :page => 2 }, :page_links => false) do
      assert_select 'a[href]', 2 do |elements|
        validate_page_numbers [1,3], elements
      end
    end
  end

  def test_will_paginate_windows
    paginate({ :page => 6, :per_page => 1 }, :inner_window => 1) do |pagination|
      assert_select 'a[href]', 8 do |elements|
        validate_page_numbers [5,1,2,5,7,10,11,7], elements
        assert_select elements.first, 'a', '&laquo; Previous'
        assert_select elements.last, 'a', 'Next &raquo;'
      end
      assert_select 'span.current', '6'
      assert_equal '&laquo; Previous 1 2 &hellip; 5 6 7 &hellip; 10 11 Next &raquo;', pagination.first.inner_text
    end
  end

  def test_will_paginate_eliminates_small_gaps
    paginate({ :page => 6, :per_page => 1 }, :inner_window => 2) do
      assert_select 'a[href]', 12 do |elements|
        validate_page_numbers [5,1,2,3,4,5,7,8,9,10,11,7], elements
      end
    end
  end
  
  def test_container_id
    paginate do |div|
      assert_nil div.first['id']
    end
    
    # magic ID
    paginate({}, :id => true) do |div|
      assert_equal 'fixnums_pagination', div.first['id']
    end
    
    # explicit ID
    paginate({}, :id => 'custom_id') do |div|
      assert_equal 'custom_id', div.first['id']
    end
  end

  ## other helpers ##
  
  def test_paginated_section
    @template = <<-ERB
      <% paginated_section collection, options do %>
        <%= content_tag :div, '', :id => "developers" %>
      <% end %>
    ERB
    
    paginate
    assert_select 'div.pagination', 2
    assert_select 'div.pagination + div#developers', 1
  end

  def test_page_entries_info
    @template = '<%= page_entries_info collection %>'
    array = ('a'..'z').to_a
    
    paginate array.paginate(:page => 2, :per_page => 5)
    assert_equal %{Displaying entries <b>6&nbsp;-&nbsp;10</b> of <b>26</b> in total},
      @html_result
    
    paginate array.paginate(:page => 7, :per_page => 4)
    assert_equal %{Displaying entries <b>25&nbsp;-&nbsp;26</b> of <b>26</b> in total},
      @html_result
  end

  def test_page_entries_info_with_single_page_collection
    @template = '<%= page_entries_info collection %>'
    
    paginate(('a'..'d').to_a.paginate(:page => 1, :per_page => 5))
    assert_equal %{Displaying <b>all 4</b> entries}, @html_result
    
    paginate(['a'].paginate(:page => 1, :per_page => 5))
    assert_equal %{Displaying <b>1</b> entry}, @html_result
    
    paginate([].paginate(:page => 1, :per_page => 5))
    assert_equal %{No entries found}, @html_result
  end
  
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

  ## internal hardcore stuff ##

  class LegacyCollection < WillPaginate::Collection
    alias :page_count :total_pages
    undef :total_pages
  end

  def test_deprecation_notices_with_page_count
    collection = LegacyCollection.new(1, 1, 2)

    assert_deprecated collection.class.name do
      paginate collection
    end
  end
  
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
  
  
  protected

    def paginate(collection = {}, options = {}, &block)
      if collection.instance_of? Hash
        page_options = { :page => 1, :total_entries => 11, :per_page => 4 }.merge(collection)
        collection = [1].paginate(page_options)
      end

      locals = { :collection => collection, :options => options }

      if defined? ActionView::Template
        # Rails 2.1
        args = [ ActionView::Template.new(@view, @template, false, locals, true, nil) ]
      else
        # older Rails versions
        args = [nil, @template, nil, locals]
      end
      
      @html_result = @view.render_template(*args)
      @html_document = HTML::Document.new(@html_result, true, false)

      if block_given?
        classname = options[:class] || WillPaginate::ViewHelpers.pagination_options[:class]
        assert_select("div.#{classname}", 1, 'no main DIV', &block)
      end
    end

    def response_from_page_or_rjs
      @html_document.root
    end

    def validate_page_numbers expected, links, param_name = :page
      param_pattern = /\W#{CGI.escape(param_name.to_s)}=([^&]*)/
      
      assert_equal(expected, links.map { |e|
        e['href'] =~ param_pattern
        $1 ? $1.to_i : $1
      })
    end

    def assert_links_match pattern, links = nil, numbers = nil
      links ||= assert_select 'div.pagination a[href]' do |elements|
        elements
      end

      pages = [] if numbers
      
      links.each do |el|
        assert_match pattern, el['href']
        if numbers
          el['href'] =~ pattern
          pages << $1.to_i
        end
      end

      assert_equal pages, numbers, "page numbers don't match" if numbers
    end

    def assert_no_links_match pattern
      assert_select 'div.pagination a[href]' do |elements|
        elements.each do |el|
          assert_no_match pattern, el['href']
        end
      end
    end
end
