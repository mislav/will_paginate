require_relative './spec_helper'
require 'sequel'
require 'will_paginate/sequel'

Sequel.sqlite.create_table :cars do
  primary_key :id, :integer, :auto_increment => true
  column :name, :text
  column :notes, :text
end

RSpec.describe Sequel::Dataset::Pagination, 'extension' do

  class Car < Sequel::Model
    self.dataset = dataset.extension(:pagination)
  end

  it "should have the #paginate method" do
    expect(Car.dataset).to respond_to(:paginate)
  end

  it "should NOT have the #paginate_by_sql method" do
    expect(Car.dataset).not_to respond_to(:paginate_by_sql)
  end

  describe 'pagination' do
    before(:all) do
      Car.create(:name => 'Shelby', :notes => "Man's best friend")
      Car.create(:name => 'Aston Martin', :notes => "Woman's best friend")
      Car.create(:name => 'Corvette', :notes => 'King of the Jungle')
    end

    it "should imitate WillPaginate::Collection" do
      result = Car.dataset.paginate(1, 2)
      
      expect(result).not_to be_empty
      expect(result.size).to eq(2)
      expect(result.length).to eq(2)
      expect(result.total_entries).to eq(3)
      expect(result.total_pages).to eq(2)
      expect(result.per_page).to eq(2)
      expect(result.current_page).to eq(1)
    end
    
    it "should perform" do
      expect(Car.dataset.paginate(1, 2).all).to eq([Car[1], Car[2]])
    end

    it "should be empty" do
      result = Car.dataset.paginate(3, 2)
      expect(result).to be_empty
    end
    
    it "should perform with #select and #order" do
      result = Car.select(Sequel.lit("name as foo")).order(:name).paginate(1, 2).all
      expect(result.size).to eq(2)
      expect(result.first.values[:foo]).to eq("Aston Martin")
    end

    it "should perform with #filter" do
      results = Car.filter(:name => 'Shelby').paginate(1, 2).all
      expect(results.size).to eq(1)
      expect(results.first).to eq(Car.find(:name => 'Shelby'))
    end
  end

end
