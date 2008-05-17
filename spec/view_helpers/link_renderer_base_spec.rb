require 'spec_helper'
require 'will_paginate/view_helpers/link_renderer_base'

describe WillPaginate::ViewHelpers::LinkRendererBase do
  it "should have gap marked initialized" do
    @renderer = create
    @renderer.gap_marker.should == '...'
  end

  it "should prepare with collection and options" do
    @renderer = create
    @renderer.prepare(collection, { :param_name => 'mypage' })
    @renderer.send(:current_page).should == 1
    @renderer.send(:param_name).should == 'mypage'
  end

  def create
    WillPaginate::ViewHelpers::LinkRendererBase.new
  end
end
