require 'spec_helper'
require 'will_paginate/page_number'
require 'json'

RSpec.describe WillPaginate::PageNumber do
  describe "valid" do
    def num
      WillPaginate::PageNumber.new('12', 'page')
    end

    it "== 12" do
      expect(num).to eq(12)
    end

    it "inspects to 'page 12'" do
      expect(num.inspect).to eq('page 12')
    end

    it "is a PageNumber" do
      expect(num.instance_of? WillPaginate::PageNumber).to be
    end

    it "is a kind of Numeric" do
      expect(num.is_a? Numeric).to be
    end

    it "is a kind of Integer" do
      expect(num.is_a? Integer).to be
    end

    it "isn't directly a Integer" do
      expect(num.instance_of? Integer).not_to be
    end

    it "passes the PageNumber=== type check" do |variable|
      expect(WillPaginate::PageNumber === num).to be
    end

    it "passes the Numeric=== type check" do |variable|
      expect(Numeric === num).to be
    end

    it "fails the Numeric=== type check" do |variable|
      expect(Integer === num).not_to be
    end

    it "serializes as JSON number" do
      expect(JSON.dump(page: num)).to eq('{"page":12}')
    end
  end

  describe "invalid" do
    def create(value, name = 'page')
      described_class.new(value, name)
    end

    it "errors out on non-int values" do
      expect { create(nil) }.to raise_error(WillPaginate::InvalidPage)
      expect { create('') }.to raise_error(WillPaginate::InvalidPage)
      expect { create('Schnitzel') }.to raise_error(WillPaginate::InvalidPage)
    end

    it "errors out on zero or less" do
      expect { create(0) }.to raise_error(WillPaginate::InvalidPage)
      expect { create(-1) }.to raise_error(WillPaginate::InvalidPage)
    end

    it "doesn't error out on zero for 'offset'" do
      expect { create(0, 'offset') }.not_to raise_error
      expect { create(-1, 'offset') }.to raise_error(WillPaginate::InvalidPage)
    end
  end

  describe "coercion method" do
    it "defaults to 'page' name" do
      num = WillPaginate::PageNumber(12)
      expect(num.inspect).to eq('page 12')
    end

    it "accepts a custom name" do
      num = WillPaginate::PageNumber(12, 'monkeys')
      expect(num.inspect).to eq('monkeys 12')
    end

    it "doesn't affect PageNumber instances" do
      num = WillPaginate::PageNumber(12)
      num2 = WillPaginate::PageNumber(num)
      expect(num2.object_id).to eq(num.object_id)
    end
  end
end
