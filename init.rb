require 'will_paginate/collection'
require 'will_paginate/finder'
require 'will_paginate/view_helpers'

ActionView::Base.send   :include, WillPaginate::ViewHelpers
ActiveRecord::Base.send :include, WillPaginate::Finder

class ActiveRecord::Associations::AssociationCollection
  include WillPaginate::Finder::ClassMethods
  alias_method_chain :method_missing, :paginate
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
