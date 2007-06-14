require 'will_paginate/collection'
require 'will_paginate/finder'
require 'will_paginate/view_helpers'

ActiveRecord::Base.send :include, WillPaginate::Finder
ActionView::Base.send   :include, WillPaginate::ViewHelpers
