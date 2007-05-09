require 'will_paginate'
require 'finder'

ActiveRecord::Base.send     :include, WillPaginate::Finder
# Controllers will get some love soon
# ActionController::Base.send :include, WillPaginate::ControllerHelpers
ActionView::Base.send       :include, WillPaginate::ViewHelpers
