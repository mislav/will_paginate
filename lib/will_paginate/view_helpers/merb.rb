require 'will_paginate/view_helpers/base'
require 'will_paginate/view_helpers/link_renderer'

WillPaginate::ViewHelpers::LinkRenderer.class_eval do
  protected

  def url(page)
    @template.url(:this, :page => page)
  end
end

Merb::AbstractController.send(:include, WillPaginate::ViewHelpers::Base)