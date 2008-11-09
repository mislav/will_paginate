require 'will_paginate/view_helpers/base'
require 'will_paginate/view_helpers/link_renderer'

WillPaginate::ViewHelpers::LinkRenderer.class_eval do
  protected

  def url(page)
    if @options[:base_url]
      "#{@options[:base_url]}?#{param_name}=#{page}"
    else
      # soon to be replaced by @template.url(:this, :page => page)
      @template.url(@template.request.route.name, @template.request.params.except(:action, :controller).merge(:page => page))
    end
  end
end

Merb::AbstractController.send(:include, WillPaginate::ViewHelpers::Base)