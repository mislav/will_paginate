require_relative './spec_helper'
require 'will_paginate/mongoid'

RSpec.describe WillPaginate::Mongoid do

  class MongoidModel
    include Mongoid::Document
  end

  before(:all) do
    Mongoid.configure do |config|
      mongodb_host = ENV["MONGODB_HOST"] || "localhost"
      mongodb_port = ENV["MONGODB_PORT"] || "27017"
      config.clients.default = {
        hosts: ["#{mongodb_host}:#{mongodb_port}"],
        database: "will_paginate_test",
      }
      config.log_level = :warn
    end

    MongoidModel.delete_all
    4.times { MongoidModel.create! }
  end

  let(:criteria) { MongoidModel.criteria }

  describe "#page" do
    it "should forward to the paginate method" do
      criteria.expects(:paginate).with(:page => 2).returns("itself")
      expect(criteria.page(2)).to eq("itself")
    end

    it "should not override per_page if set earlier in the chain" do
      expect(criteria.paginate(:per_page => 10).page(1).per_page).to eq(10)
      expect(criteria.paginate(:per_page => 20).page(1).per_page).to eq(20)
    end
  end

  describe "#per_page" do
    it "should set the limit if given an argument" do
      expect(criteria.per_page(10).options[:limit]).to eq(10)
    end

    it "should return the current limit if no argument is given" do
      expect(criteria.per_page).to eq(nil)
      expect(criteria.per_page(10).per_page).to eq(10)
    end

    it "should be interchangable with limit" do
      expect(criteria.limit(15).per_page).to eq(15)
    end

    it "should be nil'able" do
      expect(criteria.per_page(nil).per_page).to be_nil
    end
  end

  describe "#paginate" do
    it "should use criteria" do
      expect(criteria.paginate).to be_instance_of(::Mongoid::Criteria)
    end

    it "should not override page number if set earlier in the chain" do
      expect(criteria.page(3).paginate.current_page).to eq(3)
    end

    it "should limit according to per_page parameter" do
      expect(criteria.paginate(:per_page => 10).options).to include(:limit => 10)
    end

    it "should skip according to page and per_page parameters" do
      expect(criteria.paginate(:page => 2, :per_page => 5).options).to include(:skip => 5)
    end

    specify "first fallback value for per_page option is the current limit" do
      expect(criteria.limit(12).paginate.options).to include(:limit => 12)
    end

    specify "second fallback value for per_page option is WillPaginate.per_page" do
      expect(criteria.paginate.options).to include(:limit => WillPaginate.per_page)
    end

    specify "page should default to 1" do
      expect(criteria.paginate.options).to include(:skip => 0)
    end

    it "should convert strings to integers" do
      expect(criteria.paginate(:page => "2", :per_page => "3").options).to include(:limit => 3)
    end

    describe "collection compatibility" do
      describe "#total_count" do
        it "should be calculated correctly" do
          expect(criteria.paginate(:per_page => 1).total_entries).to eq(4)
          expect(criteria.paginate(:per_page => 3).total_entries).to eq(4)
        end

        it "should be cached" do
          criteria.expects(:count).once.returns(123)
          criteria.paginate
          2.times { expect(criteria.total_entries).to eq(123) }
        end
      end

      it "should calculate total_pages" do
        expect(criteria.paginate(:per_page => 1).total_pages).to eq(4)
        expect(criteria.paginate(:per_page => 3).total_pages).to eq(2)
        expect(criteria.paginate(:per_page => 10).total_pages).to eq(1)
      end

      it "should return per_page" do
        expect(criteria.paginate(:per_page => 1).per_page).to eq(1)
        expect(criteria.paginate(:per_page => 5).per_page).to eq(5)
      end

      describe "#current_page" do
        it "should return current_page" do
          expect(criteria.paginate(:page => 1).current_page).to eq(1)
          expect(criteria.paginate(:page => 3).current_page).to eq(3)
        end

        it "should be casted to PageNumber" do
          page = criteria.paginate(:page => 1).current_page
          expect(page.instance_of? WillPaginate::PageNumber).to be
        end
      end

      it "should return offset" do
        expect(criteria.paginate(:page => 1).offset).to eq(0)
        expect(criteria.paginate(:page => 2, :per_page => 5).offset).to eq(5)
        expect(criteria.paginate(:page => 3, :per_page => 10).offset).to eq(20)
      end

      it "should not pollute plain mongoid criterias" do
        %w(total_entries total_pages current_page).each do |method|
          expect(criteria).not_to respond_to(method)
        end
      end
    end
  end
end
