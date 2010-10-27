require 'will_paginate/fixes/support_count'
# require '../../../helper'

class SupportCountTest < Test::Unit::TestCase
  
  class SimpleReturn
    def self.construct_count_options_from_args(*args)
      ["custom value"]
    end
  end
  
  def test_result_should_be_itself_if_not_ending_in_dot_star
    SimpleReturn.send :include, WillPaginate::Fixes::CountFix
    assert_equal ["custom value"], SimpleReturn.send(:construct_count_options_from_args)
  end

end
