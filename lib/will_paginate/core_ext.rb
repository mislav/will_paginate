require 'set'
require 'will_paginate/array'

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

unless Hash.instance_methods.include? 'rec_merge'
  Hash.class_eval do
    def rec_merge(other)
      res = self.clone
      other.each do |key, other_value|
        value = res[key]
        if value.is_a?(Hash) and other_value.is_a?(Hash)
          res[key] = value.rec_merge other_value
        else
          res[key] = other_value
        end
      end
      res
    end 
  end
end
