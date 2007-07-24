require 'will_paginate/core_ext'
require 'will_paginate/collection'
require 'will_paginate/finder'
require 'will_paginate/view_helpers'

ActionView::Base.send   :include, WillPaginate::ViewHelpers
ActiveRecord::Base.send :include, WillPaginate::Finder

module ActiveRecord::Associations
  # to support paginating finders on associations, we have to mix in the
  # method_missing magic from WillPaginate::Finder::ClassMethods to AssociationProxy
  # subclasses, but in a different way for Rails 1.2.x and 2.0
  (AssociationCollection.instance_methods.include?(:create!) ?
    AssociationCollection : AssociationCollection.subclasses.map(&:constantize)
  ).push(HasManyThroughAssociation).each do |klass|
    klass.class_eval do
      include WillPaginate::Finder::ClassMethods
      alias_method_chain :method_missing, :paginate
    end
  end
end
