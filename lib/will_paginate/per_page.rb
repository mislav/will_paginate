module WillPaginate
  module PerPage
    def per_page
      defined?(@per_page) ? @per_page : WillPaginate.per_page
    end

    def per_page=(limit)
      @per_page = limit.to_i
    end

    def self.extended(base)
      base.extend Inheritance if base.is_a? Class
    end

    module Inheritance
      def inherited(subclass)
        super
        subclass.per_page = self.per_page
      end
    end
  end

  extend PerPage

  # default number of items per page
  self.per_page = 30

  # these methods are used internally and are subject to change
  module Calculation
    def process_values(page, per_page)
      page = page.nil? ? 1 : InvalidPage.validate(page, 'page')
      per_page = per_page.to_i
      offset = calculate_offset(page, per_page)
      [page, per_page, offset]
    end

    def calculate_offset(page, per_page)
      InvalidPage.validate((page - 1) * per_page, 'offset')
    end
  end

  extend Calculation

  # Raised by paginating methods in case `page` parameter is an invalid number.
  #
  # In Rails this error is automatically handled as 404 Not Found.
  class InvalidPage < ArgumentError
    # the maximum value for SQL BIGINT
    BIGINT = 9223372036854775807

    # Returns value cast to integer, raising self if invalid
    def self.validate(value, name)
      num = value.to_i
    rescue NoMethodError
      raise self, "#{name} cannot be converted to integer: #{value.inspect}"
    else
      if 'offset' == name ? (num < 0 or num > BIGINT) : num < 1
        raise self, "invalid #{name}: #{value.inspect}"
      end
      return num
    end
  end
end
