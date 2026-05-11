# You will paginate!
module WillPaginate
end

if defined?(Rails::Railtie)
  require 'will_paginate/railtie'
elsif defined?(Rails::Initializer)
  raise "will_paginate 3.0 is not compatible with Rails 2.3 or older"
end

if defined?(Sinatra) and Sinatra.respond_to? :register
  require 'will_paginate/view_helpers/sinatra'
end
