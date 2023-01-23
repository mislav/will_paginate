require_relative './spec_helper'
require 'will_paginate/data_mapper'
require_relative './data_mapper_test_connector'

RSpec.describe "WillPaginate::DataMapper" do

  before(:all) do
    DataMapper.setup :default, 'sqlite3::memory:'
    [Animal, Ownership, Human].each do |klass|
      klass.auto_migrate!
    end

    Animal.create(:name => 'Dog', :notes => 'a friend of all')
    Animal.create(:name => 'Cat', :notes => 'a friend or foe')
    Animal.create(:name => 'Lion', :notes => 'some roar')
  end

  it "has per_page" do
    expect(Animal.per_page).to eq(30)
    begin
      Animal.per_page = 10
      expect(Animal.per_page).to eq(10)

      subclass = Class.new(Animal)
      expect(subclass.per_page).to eq(10)
    ensure
      Animal.per_page = 30
    end
  end

  it "doesn't make normal collections appear paginated" do
    expect(Animal.all).not_to be_paginated
  end

  it "paginates to first page by default" do
    animals = Animal.paginate(:page => nil)

    expect(animals).to be_paginated
    expect(animals.current_page).to eq(1)
    expect(animals.per_page).to eq(30)
    expect(animals.offset).to eq(0)
    expect(animals.total_entries).to eq(3)
    expect(animals.total_pages).to eq(1)
  end

  it "paginates to first page, explicit limit" do
    animals = Animal.paginate(:page => 1, :per_page => 2)

    expect(animals.current_page).to eq(1)
    expect(animals.per_page).to eq(2)
    expect(animals.total_entries).to eq(3)
    expect(animals.total_pages).to eq(2)
    expect(animals.map {|a| a.name }).to eq(%w[ Dog Cat ])
  end

  it "paginates to second page" do
    animals = Animal.paginate(:page => 2, :per_page => 2)

    expect(animals.current_page).to eq(2)
    expect(animals.offset).to eq(2)
    expect(animals.map {|a| a.name }).to eq(%w[ Lion ])
  end

  it "paginates a collection" do
    friends = Animal.all(:notes.like => '%friend%')
    expect(friends.paginate(:page => 1).per_page).to eq(30)
    expect(friends.paginate(:page => 1, :per_page => 1).total_entries).to eq(2)
  end

  it "paginates a limited collection" do
    animals = Animal.all(:limit => 2).paginate(:page => 1)
    expect(animals.per_page).to eq(2)
  end

  it "has page() method" do
    expect(Animal.page(2).per_page).to eq(30)
    expect(Animal.page(2).offset).to eq(30)
    expect(Animal.page(2).current_page).to eq(2)
    expect(Animal.all(:limit => 2).page(2).per_page).to eq(2)
  end

  it "has total_pages at 1 for empty collections" do
    expect(Animal.all(:conditions => ['1=2']).page(1).total_pages).to eq(1)
  end

  it "overrides total_entries count with a fixed value" do
    animals = Animal.paginate :page => 1, :per_page => 3, :total_entries => 999
    expect(animals.total_entries).to eq(999)
  end

  it "supports a non-int for total_entries" do
    topics = Animal.paginate :page => 1, :per_page => 3, :total_entries => "999"
    expect(topics.total_entries).to eq(999)
  end


  it "can iterate and then call WP methods" do
    animals = Animal.all(:limit => 2).page(1)
    animals.each { |a| }
    expect(animals.total_entries).to eq(3)
  end

  it "augments to_a to return a WP::Collection" do
    animals = Animal.all(:limit => 2).page(1)
    array = animals.to_a
    expect(array.size).to eq(2)
    expect(array).to be_kind_of(WillPaginate::Collection)
    expect(array.current_page).to eq(1)
    expect(array.per_page).to eq(2)
  end

  it "doesn't have a problem assigning has-one-through relationship" do
    human = Human.create :name => "Mislav"
    human.pet = Animal.first
  end

end
