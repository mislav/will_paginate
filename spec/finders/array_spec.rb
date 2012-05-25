require 'will_paginate/array'
require 'spec_helper'

describe Array do
  before :all do
    @simple = (1..99).to_a
  end

  it "supports the page() method" do
    @simple.page(1).should == (1..30).to_a
    @simple.page(2).should == (31..60).to_a
  end
end
