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

unless Array.instance_methods.include? 'paginate'
  # http://www.desimcadam.com/archives/8
  Array.class_eval do
    def paginate(page = 1, per_page = 15)
      pagination_array = WillPaginate::Collection.new(page, per_page, size)
      start_index = pagination_array.offset
      end_index = start_index + (per_page - 1)
      array_to_concat = self[start_index..end_index]
      array_to_concat.nil? ? [] : pagination_array.concat(array_to_concat)
    end
  end
end
