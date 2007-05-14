ActiveRecord::Base.send :include, WillPaginate::Finder
ActionView::Base.send   :include, WillPaginate::ViewHelpers
