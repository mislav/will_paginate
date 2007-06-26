require 'will_paginate/collection'
require 'will_paginate/finder'
require 'will_paginate/view_helpers'

ActionView::Base.send   :include, WillPaginate::ViewHelpers
ActiveRecord::Base.send :include, WillPaginate::Finder

class ActiveRecord::Associations::AssociationCollection
  include WillPaginate::Finder::ClassMethods
  alias_method_chain :method_missing, :paginate
end
