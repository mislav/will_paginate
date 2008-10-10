require 'spec_helper'
require 'action_controller'
require 'action_controller/assertions/selector_assertions'
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
  
  include ActionController::Assertions::SelectorAssertions
  
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
  
  def assert(value, message)
    raise message unless value
  end
  
  def paginate(collection = {}, options = {}, &block)
    if collection.instance_of? Hash
      page_options = { :page => 1, :total_entries => 11, :per_page => 4 }.merge(collection)
      collection = [1].paginate(page_options)
    end

    locals = { :collection => collection, :options => options }

    @render_output = @view.render(:inline => @template, :locals => locals)
    
    if block_given?
      classname = options[:class] || WillPaginate::ViewHelpers.pagination_options[:class]
      assert_select("div.#{classname}", 1, 'no main DIV', &block)
    end
  end
  
  def html_document
    @html_document ||= HTML::Document.new(@render_output, true, false)
  end
  
  def response_from_page_or_rjs
    html_document.root
  end
  
  def validate_page_numbers(expected, links, param_name = :page)
    param_pattern = /\W#{CGI.escape(param_name.to_s)}=([^&]*)/
    
    links.map { |e|
      e['href'] =~ param_pattern
      $1 ? $1.to_i : $1
    }.should == expected
  end

  def assert_links_match(pattern, links = nil, numbers = nil)
    links ||= assert_select 'div.pagination a[href]' do |elements|
      elements
    end

    pages = [] if numbers
    
    links.each do |el|
      el['href'].should =~ pattern
      if numbers
        el['href'] =~ pattern
        pages << ($1.nil?? nil : $1.to_i)
      end
    end

    pages.should == numbers if numbers
  end

  def assert_no_links_match(pattern)
    assert_select 'div.pagination a[href]' do |elements|
      elements.each do |el|
        el['href'] !~ pattern
      end
    end
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

module HTML
  Node.class_eval do
    def inner_text
      children.map(&:inner_text).join('')
    end
  end
  
  Text.class_eval do
    def inner_text
      self.to_s
    end
  end

  Tag.class_eval do
    def inner_text
      childless?? '' : super
    end
  end
end
