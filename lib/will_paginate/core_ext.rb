require 'set'

unless Hash.instance_methods.include? 'except'
  Hash.class_eval do
    # Returns a new hash without the given keys.
    def except(*keys)
      rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      reject { |key,| rejected.include?(key) }
    end
 
    # Replaces the hash without only the given keys.
    def except!(*keys)
      replace(except(*keys))
    end
  end
end

unless Hash.instance_methods.include? 'slice'
  Hash.class_eval do
    # Returns a new hash with only the given keys.
    def slice(*keys)
      allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      reject { |key,| !allowed.include?(key) }
    end

    # Replaces the hash with only the given keys.
    def slice!(*keys)
      replace(slice(*keys))
    end
  end
end

require 'will_paginate/collection'

unless Array.instance_methods.include? 'paginate'
  # http://www.desimcadam.com/archives/8
  Array.class_eval do
    def paginate(options_or_page = {}, per_page = nil)
      if options_or_page.nil? or Fixnum === options_or_page
        if defined? WillPaginate::Deprecation
          WillPaginate::Deprecation.warn <<-DEPR
            Array#paginate now conforms to the main, ActiveRecord::Base#paginate API.  You should \
            call it with a parameters hash (:page, :per_page).  The old API (numbers as arguments) \
            has been deprecated and is going to be unsupported in future versions of will_paginate.
          DEPR
        end
        page = options_or_page
        options = {}
      else
        options = options_or_page
        page = options[:page] || 1
        raise ArgumentError, "wrong number of arguments (1 hash or 2 Fixnums expected)" if per_page
        per_page = options[:per_page]
      end

      WillPaginate::Collection.create(page || 1, per_page || 30, options[:total_entries] || size) do |pager|
        pager.replace self[pager.offset, pager.per_page].to_a
      end
    end
  end
end
