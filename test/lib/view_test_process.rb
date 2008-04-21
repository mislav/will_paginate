require 'action_controller'
require 'action_controller/test_process'

require 'will_paginate'
WillPaginate.enable_actionpack

ActionController::Routing::Routes.draw do |map|
  map.connect 'dummy/page/:page', :controller => 'dummy'
  map.connect ':controller/:action/:id'
end

ActionController::Base.perform_caching = false

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

class DummyController
  attr_reader :request
  attr_accessor :controller_name
  
  def initialize
    @request = DummyRequest.new
    @url = ActionController::UrlRewriter.new(@request, @request.params)
  end
  
  def url_for(params)
    @url.rewrite(params)
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
