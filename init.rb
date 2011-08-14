require 'will_paginate'

# This is all duplication of what Railtie does, but is necessary because
# the initializer defined by the Railtie won't ever run when loaded as plugin.

if defined? ActiveRecord::Base
  require 'will_paginate/active_record'
end

if defined? ActionController::Base
  WillPaginate::Railtie.setup_actioncontroller
end

if defined? ActionView::Base
  require 'will_paginate/view_helpers/action_view'
end

WillPaginate::Railtie.add_locale_path config
