require 'will_paginate/array'
require 'spec_helper'

describe Array do
  subject { (1..99).to_a }

  it "supports the page() method" do
    subject.page(1).should == (1..30).to_a
    subject.page(2).should == (31..60).to_a
  end
end
