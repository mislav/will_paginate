require 'spec_helper'
require 'will_paginate/mongoid'

Mongoid.database = Mongo::Connection.new.db('will_paginate_test')

class MongoidModel
  include Mongoid::Document
end

describe "will paginate mongoid" do
  it "should have the #paginate method" do
    MongoidModel.criteria.should respond_to(:paginate)
  end

  describe "pagination" do
    before(:all) do
      MongoidModel.delete_all
      4.times { MongoidModel.create! }
    end

    it "should use criteria" do
      MongoidModel.all.paginate.should be_instance_of(::Mongoid::Criteria)
    end

    it "should limit according to per_page parameter" do
      criteria = MongoidModel.all.paginate(:per_page => 10)
      criteria.options.should include(:limit => 10)
    end

    it "should skip according to page and per_page parameters" do
      criteria = MongoidModel.all.paginate(:page => 2, :per_page => 5)
      criteria.options.should include(:skip => 5)
    end

    specify "per_page should default to value configured for WillPaginate" do
      criteria = MongoidModel.all.paginate
      criteria.options.should include(:limit => WillPaginate.per_page)
    end

    specify "page should default to 1" do
      MongoidModel.all.paginate.options.should include(:skip => 0)
    end

    it "should convert strings to integers" do
      MongoidModel.all.paginate(:page => "2", :per_page => "3").options.should include(:limit => 3, :limit => 3)
    end

    describe "collection compatibility" do
      it "should calculate total_count" do
        MongoidModel.all.paginate(:per_page => 1).total_entries.should == 4
        MongoidModel.all.paginate(:per_page => 3).total_entries.should == 4
      end

      it "should calculate total_pages" do
        MongoidModel.all.paginate(:per_page => 1).total_pages.should == 4
        MongoidModel.all.paginate(:per_page => 3).total_pages.should == 2
        MongoidModel.all.paginate(:per_page => 10).total_pages.should == 1
      end

      it "should return per_page" do
        MongoidModel.all.paginate(:per_page => 1).per_page.should == 1
        MongoidModel.all.paginate(:per_page => 5).per_page.should == 5
      end

      it "should return current_page" do
        MongoidModel.all.paginate(:page => 1).current_page.should == 1
        MongoidModel.all.paginate(:page => 3).current_page.should == 3
      end

      it "should return offset" do
        MongoidModel.all.paginate(:page => 1).offset.should == 0
        MongoidModel.all.paginate(:page => 2, :per_page => 5).offset.should == 5
        MongoidModel.all.paginate(:page => 3, :per_page => 10).offset.should == 20
      end

      it "should not pollute plain mongoid criterias" do
        criteria = MongoidModel.criteria
        %w(total_entries total_pages per_page current_page).each do |method|
          criteria.should_not respond_to(method)
        end
        criteria.offset.should be_nil # this is already a criteria method
      end
    end
  end
end
