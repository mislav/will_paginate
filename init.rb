require 'will_paginate'
require 'finder'
ActionView::Base.send(:include, WillPaginate)
ActiveRecord::Base.send(:include, Finder)
