unless ActiveRecord::Base.respond_to? :paginate
  require 'will_paginate'
  WillPaginate.enable
end
