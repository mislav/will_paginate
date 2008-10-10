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
  
  def render(locals)
    @view.render(:inline => @template, :locals => locals)
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
