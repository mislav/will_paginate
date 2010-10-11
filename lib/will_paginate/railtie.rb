require 'will_paginate'
require 'will_paginate/collection'

module WillPaginate
  class Railtie < Rails::Railtie
    initializer "will_paginate.active_record" do |app|
      ActiveSupport.on_load :active_record do
        require 'will_paginate/finders/active_record'
        WillPaginate::Finders::ActiveRecord.enable!
      end
    end
    
    initializer "will_paginate.action_dispatch" do |app|
      ActiveSupport.on_load :action_controller do
        ActionDispatch::ShowExceptions.rescue_responses['WillPaginate::InvalidPage'] = :not_found
      end
    end
    
    initializer "will_paginate.action_view" do |app|
      ActiveSupport.on_load :action_view do
        require 'will_paginate/view_helpers/action_view'
        include WillPaginate::ViewHelpers::ActionView
      end
    end
  end
end
