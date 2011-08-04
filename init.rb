require 'will_paginate'

# This is all duplication of what Railtie does, but is necessary because
# the initializer defined by the Railtie won't ever run when loaded as plugin.

if defined? ActiveRecord::Base
  WillPaginate::Railtie.setup_activerecord
end

if defined? ActionController::Base
  WillPaginate::Railtie.setup_actioncontroller
end

if defined? ActionView::Base
  WillPaginate::Railtie.setup_actionview
end

WillPaginate::Railtie.add_locale_path config
