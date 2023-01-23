require 'will_paginate/array'
require 'spec_helper'

RSpec.describe WillPaginate::Collection do

  before :all do
    @simple = ('a'..'e').to_a
  end

  it "should be a subset of original collection" do
    expect(@simple.paginate(:page => 1, :per_page => 3)).to eq(%w( a b c ))
  end

  it "can be shorter than per_page if on last page" do
    expect(@simple.paginate(:page => 2, :per_page => 3)).to eq(%w( d e ))
  end

  it "should include whole collection if per_page permits" do
    expect(@simple.paginate(:page => 1, :per_page => 5)).to eq(@simple)
  end

  it "should be empty if out of bounds" do
    expect(@simple.paginate(:page => 2, :per_page => 5)).to be_empty
  end
  
  it "should default to 1 as current page and 30 per-page" do
    result = (1..50).to_a.paginate
    expect(result.current_page).to eq(1)
    expect(result.size).to eq(30)
  end

  it "should give total_entries precedence over actual size" do
    expect(%w(a b c).paginate(:total_entries => 5).total_entries).to eq(5)
  end

  it "should be an augmented Array" do
    entries = %w(a b c)
    collection = create(2, 3, 10) do |pager|
      expect(pager.replace(entries)).to eq(entries)
    end

    expect(collection).to eq(entries)
    for method in %w(total_pages each offset size current_page per_page total_entries)
      expect(collection).to respond_to(method)
    end
    expect(collection).to be_kind_of(Array)
    expect(collection.entries).to be_instance_of(Array)
    # TODO: move to another expectation:
    expect(collection.offset).to eq(3)
    expect(collection.total_pages).to eq(4)
    expect(collection).not_to be_out_of_bounds
  end

  describe "previous/next pages" do
    it "should have previous_page nil when on first page" do
      collection = create(1, 1, 3)
      expect(collection.previous_page).to be_nil
      expect(collection.next_page).to eq(2)
    end
    
    it "should have both prev/next pages" do
      collection = create(2, 1, 3)
      expect(collection.previous_page).to eq(1)
      expect(collection.next_page).to eq(3)
    end
    
    it "should have next_page nil when on last page" do
      collection = create(3, 1, 3)
      expect(collection.previous_page).to eq(2)
      expect(collection.next_page).to be_nil
    end
  end

  describe "out of bounds" do
    it "is out of bounds when page number is too high" do
      expect(create(2, 3, 2)).to be_out_of_bounds
    end

    it "isn't out of bounds when inside collection" do
      expect(create(1, 3, 2)).not_to be_out_of_bounds
    end

    it "isn't out of bounds when the collection is empty" do
      collection = create(1, 3, 0)
      expect(collection).not_to be_out_of_bounds
      expect(collection.total_pages).to eq(1)
    end
  end

  describe "guessing total count" do
    it "can guess when collection is shorter than limit" do
      collection = create { |p| p.replace array }
      expect(collection.total_entries).to eq(8)
    end
    
    it "should allow explicit total count to override guessed" do
      collection = create(2, 5, 10) { |p| p.replace array }
      expect(collection.total_entries).to eq(10)
    end
    
    it "should not be able to guess when collection is same as limit" do
      collection = create { |p| p.replace array(5) }
      expect(collection.total_entries).to be_nil
    end
    
    it "should not be able to guess when collection is empty" do
      collection = create { |p| p.replace array(0) }
      expect(collection.total_entries).to be_nil
    end
    
    it "should be able to guess when collection is empty and this is the first page" do
      collection = create(1) { |p| p.replace array(0) }
      expect(collection.total_entries).to eq(0)
    end
  end

  it "should not respond to page_count anymore" do
    expect { create.page_count }.to raise_error(NoMethodError)
  end

  it "inherits per_page from global value" do
    collection = described_class.new(1)
    expect(collection.per_page).to eq(30)
  end

  private
  
    def create(page = 2, limit = 5, total = nil, &block)
      if block_given?
        described_class.create(page, limit, total, &block)
      else
        described_class.new(page, limit, total)
      end
    end

    def array(size = 3)
      Array.new(size)
    end
end
