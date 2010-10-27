# monkeypatch Rails ticket #2189: "count breaks has_many :through"
class WillPaginate::Fixes::SupportCount
  
  def fix_something(what)
    class << what
      alias_method :construct_count_options_from_args_without_will_paginate_fix, :construct_count_options_from_args
      def construct_count_options_from_args(*args)
        result = construct_count_options_from_args_without_will_paginate_fix(*args)
        result[0] = '*' if result[0].is_a?(String) and result[0] =~ /\.\*$/
        result
      end
    end
  end
  
  def fix
    fix_something(ActiveRecord::Base)
  end
  
end
