require 'spec_helper'
require 'will_paginate/page_number'

describe WillPaginate::PageNumber do
  describe "valid" do
    subject { described_class.new('12', 'page') }

    it { should eq(12) }
    its(:inspect) { should eq('page 12') }
    it { should be_a(WillPaginate::PageNumber) }
    it { should be_instance_of(WillPaginate::PageNumber) }
    it { should be_a(Numeric) }
    it { should be_a(Fixnum) }
    it { should_not be_instance_of(Fixnum) }

    it "passes the PageNumber=== type check" do |variable|
      (WillPaginate::PageNumber === subject).should be
    end

    it "passes the Numeric=== type check" do |variable|
      (Numeric === subject).should be
      (Fixnum === subject).should be
    end
  end

  describe "invalid" do
    def create(value, name = 'page')
      described_class.new(value, name)
    end

    it "errors out on non-int values" do
      lambda { create(nil) }.should raise_error(WillPaginate::InvalidPage)
      lambda { create('') }.should raise_error(WillPaginate::InvalidPage)
      lambda { create('Schnitzel') }.should raise_error(WillPaginate::InvalidPage)
    end

    it "errors out on zero or less" do
      lambda { create(0) }.should raise_error(WillPaginate::InvalidPage)
      lambda { create(-1) }.should raise_error(WillPaginate::InvalidPage)
    end

    it "doesn't error out on zero for 'offset'" do
      lambda { create(0, 'offset') }.should_not raise_error
      lambda { create(-1, 'offset') }.should raise_error(WillPaginate::InvalidPage)
    end
  end

  describe "coercion method" do
    it "defaults to 'page' name" do
      num = WillPaginate::PageNumber(12)
      num.inspect.should eq('page 12')
    end

    it "accepts a custom name" do
      num = WillPaginate::PageNumber(12, 'monkeys')
      num.inspect.should eq('monkeys 12')
    end

    it "doesn't affect PageNumber instances" do
      num = WillPaginate::PageNumber(12)
      num2 = WillPaginate::PageNumber(num)
      num2.object_id.should eq(num.object_id)
    end
  end
end
