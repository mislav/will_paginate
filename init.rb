ActiveRecord::Base.send :include, WillPaginate::Finder
ActionView::Base.send   :include, WillPaginate::ViewHelpers

unless Hash.new.respond_to? :slice
  class Hash
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
