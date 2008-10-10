require 'spec_helper'
require 'action_controller'
require 'view_helpers/view_example_group'
require 'will_paginate/view_helpers/action_view'
require 'will_paginate/collection'

ActionController::Routing::Routes.draw do |map|
  map.connect 'dummy/page/:page', :controller => 'dummy'
  map.connect 'dummy/dots/page.:page', :controller => 'dummy', :action => 'dots'
  map.connect 'ibocorp/:page', :controller => 'ibocorp',
                               :requirements => { :page => /\d+/ },
                               :defaults => { :page => 1 }
                               
  map.connect ':controller/:action/:id'
end

describe WillPaginate::ViewHelpers::ActionView do
  before(:each) do
    @view = ActionView::Base.new
    @view.controller = DummyController.new
    @view.request = @view.controller.request
    @template = '<%= will_paginate collection, options %>'
  end
  
  def render(locals)
    @view.render(:inline => @template, :locals => locals)
  end
  
  ## basic pagination ##
  
  it "should render" do
    paginate do |pagination|
      assert_select 'a[href]', 3 do |elements|
        validate_page_numbers [2,3,2], elements
        assert_select elements.last, ':last-child', "Next &raquo;"
      end
      assert_select 'span', 2
      assert_select 'span.disabled:first-child', '&laquo; Previous'
      assert_select 'span.current', '1'
      pagination.first.inner_text.should == '&laquo; Previous 1 2 3 Next &raquo;'
    end
  end

  it "should render nothing when there is only 1 page" do
    paginate(:per_page => 30).should be_empty
  end

  it "should paginate with options" do
    paginate({ :page => 2 }, :class => 'will_paginate', :prev_label => 'Prev', :next_label => 'Next') do
      assert_select 'a[href]', 4 do |elements|
        validate_page_numbers [1,1,3,3], elements
        # test rel attribute values:
        assert_select elements[1], 'a', '1' do |link|
          link.first['rel'].should == 'prev start'
        end
        assert_select elements.first, 'a', "Prev" do |link|
          link.first['rel'].should == 'prev start'
        end
        assert_select elements.last, 'a', "Next" do |link|
          link.first['rel'].should == 'next'
        end
      end
      assert_select 'span.current', '2'
    end
  end

  it "should paginate using a custom renderer class" do
    paginate({}, :renderer => AdditionalLinkAttributesRenderer) do
      assert_select 'a[default=true]', 3
    end
  end

  it "should paginate using a custom renderer instance" do
    renderer = WillPaginate::ViewHelpers::LinkRenderer.new
    renderer.gap_marker = '<span class="my-gap">~~</span>'
    
    paginate({ :per_page => 2 }, :inner_window => 0, :outer_window => 0, :renderer => renderer) do
      assert_select 'span.my-gap', '~~'
    end
    
    renderer = AdditionalLinkAttributesRenderer.new(:title => 'rendered')
    paginate({}, :renderer => renderer) do
      assert_select 'a[title=rendered]', 3
    end
  end

  it "should have classnames on previous/next links" do
    paginate do |pagination|
      assert_select 'span.disabled.prev_page:first-child'
      assert_select 'a.next_page[href]:last-child'
    end
  end

  it "should match expected markup" do
    paginate
    expected = <<-HTML
      <div class="pagination"><span class="disabled prev_page">&laquo; Previous</span>
      <span class="current">1</span>
      <a href="/foo/bar?page=2" rel="next">2</a>
      <a href="/foo/bar?page=3">3</a>
      <a href="/foo/bar?page=2" class="next_page" rel="next">Next &raquo;</a></div>
    HTML
    expected.strip!.gsub!(/\s{2,}/, ' ')
    expected_dom = HTML::Document.new(expected).root
    
    html_document.root.should == expected_dom
  end
  
  ## advanced options for pagination ##

  it "should be able to render without container" do
    paginate({}, :container => false)
    assert_select 'div.pagination', 0, 'main DIV present when it shouldn\'t'
    assert_select 'a[href]', 3
  end

  it "should be able to render without page links" do
    paginate({ :page => 2 }, :page_links => false) do
      assert_select 'a[href]', 2 do |elements|
        validate_page_numbers [1,3], elements
      end
    end
  end

  it "should have magic HTML ID for the container" do
    paginate do |div|
      div.first['id'].should be_nil
    end
    
    # magic ID
    paginate({}, :id => true) do |div|
      div.first['id'].should == 'fixnums_pagination'
    end
    
    # explicit ID
    paginate({}, :id => 'custom_id') do |div|
      div.first['id'].should == 'custom_id'
    end
  end

  ## other helpers ##
  
  it "should render a paginated section" do
    @template = <<-ERB
      <% paginated_section collection, options do %>
        <%= content_tag :div, '', :id => "developers" %>
      <% end %>
    ERB
    
    paginate
    assert_select 'div.pagination', 2
    assert_select 'div.pagination + div#developers', 1
  end
end

class AdditionalLinkAttributesRenderer < WillPaginate::ViewHelpers::LinkRenderer
  def initialize(link_attributes = nil)
    super()
    @additional_link_attributes = link_attributes || { :default => 'true' }
  end

  def page_link(page, text, attributes = {})
    @template.link_to text, url_for(page), attributes.merge(@additional_link_attributes)
  end
end

class DummyController
  attr_reader :request
  attr_accessor :controller_name
  
  def initialize
    @request = DummyRequest.new
    @url = ActionController::UrlRewriter.new(@request, @request.params)
  end

  def params
    @request.params
  end
  
  def url_for(params)
    @url.rewrite(params)
  end
end

class DummyRequest
  attr_accessor :symbolized_path_parameters
  
  def initialize
    @get = true
    @params = {}
    @symbolized_path_parameters = { :controller => 'foo', :action => 'bar' }
  end
  
  def get?
    @get
  end

  def post
    @get = false
  end

  def relative_url_root
    ''
  end

  def params(more = nil)
    @params.update(more) if more
    @params
  end
end
