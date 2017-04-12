require 'delegate'
require 'forwardable'

module WillPaginate
  # a module that page number exceptions are tagged with
  module InvalidPage; end

  # integer representing a page number
  class PageNumber < DelegateClass(Integer)
    # a value larger than this is not supported in SQL queries
    BIGINT = 9223372036854775807

    extend Forwardable

    def initialize(value, name)
      value = Integer(value)
      if 'offset' == name ? (value < 0 or value > BIGINT) : value < 1
        raise RangeError, "invalid #{name}: #{value.inspect}"
      end
      @name = name
      super(value)
    rescue ArgumentError, TypeError, RangeError => error
      error.extend InvalidPage
      raise error
    end

    alias_method :to_i, :__getobj__

    def inspect
      "#{@name} #{to_i}"
    end

    def to_offset(per_page)
      PageNumber.new((to_i - 1) * per_page.to_i, 'offset')
    end

    def kind_of?(klass)
      super || to_i.kind_of?(klass)
    end
    alias is_a? kind_of?
  end

  # Ultrahax: makes `Integer === current_page` checks pass
  Numeric.extend Module.new {
    def ===(obj)
      obj.instance_of? PageNumber or super
    end
  }

  # An idemptotent coercion method
  def self.PageNumber(value, name = 'page')
    case value
    when PageNumber then value
    else PageNumber.new(value, name)
    end
  end
end
