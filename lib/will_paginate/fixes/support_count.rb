# monkeypatch Rails ticket #2189: "count breaks has_many :through"
module WillPaginate::Fixes::CountFix
  module ClassMethods
    # protected
    def construct_count_options_from_args(*args)
      result = super
      result[0] = '*' if result[0].is_a?(String) and result[0] =~ /\.\*$/
      result
    end  
    def x
      puts "x"*50
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
  end
end

class WillPaginate::Fixes::SupportCount

  def fix
    ActiveRecord::Base.send :include, WillPaginate::Fixes::CountFix
  end
end
