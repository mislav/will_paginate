require 'will_paginate/fixes/support_count'

class SupportCountTest < Test::Unit::TestCase
  
  class SimpleReturn
    def self.construct_count_options_from_args(*args)
      ["custom value"]
    end
  end
  
  def test_result_should_be_itself_if_not_ending_in_dot_star
    WillPaginate::Fixes::SupportCount.new.fix_something(SimpleReturn)
    assert_equal ["custom value"], SimpleReturn.send(:construct_count_options_from_args)
  end

  class AsteriskReturn
    def self.construct_count_options_from_args(*args)
      ["custom value.*"]
    end
  end
  
  def test_result_should_be_star_if_ending_in_dot_star
    WillPaginate::Fixes::SupportCount.new.fix_something(AsteriskReturn)
    assert_equal ["*"], AsteriskReturn.send(:construct_count_options_from_args)
  end

end
