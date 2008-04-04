require 'set'
require 'will_paginate/collection'

unless Array.instance_methods.include? 'paginate'
  # http://www.desimcadam.com/archives/8
  Array.class_eval do
    def paginate(options = {})
      raise ArgumentError, "parameter hash expected (got #{options.inspect})" unless Hash === options
      
      WillPaginate::Collection.create(
          options[:page] || 1,
          options[:per_page] || 30,
          options[:total_entries] || self.length
      ) { |pager|
        pager.replace self[pager.offset, pager.per_page].to_a
      }
    end
  end
end

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

unless Hash.instance_methods.include? 'rec_merge!'
  Hash.class_eval do
    # Same as Hash#merge!, but recursively merges sub-hashes
    # (stolen from Haml)
    def rec_merge!(other)
      other.each do |key, other_value|
        value = self[key]
        if value.is_a?(Hash) and other_value.is_a?(Hash)
          value.rec_merge! other_value
        else
          self[key] = other_value
        end
      end
      self
    end
  end
end
