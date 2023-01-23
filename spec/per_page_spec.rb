require 'spec_helper'
require 'will_paginate/per_page'

RSpec.describe WillPaginate::PerPage do

  class MyModel
    extend WillPaginate::PerPage
  end

  it "has the default value" do
    expect(MyModel.per_page).to eq(30)

    WillPaginate.per_page = 10
    begin
      expect(MyModel.per_page).to eq(10)
    ensure
      WillPaginate.per_page = 30
    end
  end

  it "casts values to int" do
    WillPaginate.per_page = '10'
    begin
      expect(MyModel.per_page).to eq(10)
    ensure
      WillPaginate.per_page = 30
    end
  end

  it "has an explicit value" do
    MyModel.per_page = 12
    begin
      expect(MyModel.per_page).to eq(12)
      subclass = Class.new(MyModel)
      expect(subclass.per_page).to eq(12)
    ensure
      MyModel.send(:remove_instance_variable, '@per_page')
    end
  end

end
