require 'will_paginate'
require 'will_paginate/collection'

module WillPaginate
  class Railtie < Rails::Railtie
    initializer "will_paginate" do |app|
      ActiveSupport.on_load :active_record do
        require 'will_paginate/active_record'
        WillPaginate::ActiveRecord.setup
      end

      ActiveSupport.on_load :action_controller do
        ActionDispatch::ShowExceptions.rescue_responses['WillPaginate::InvalidPage'] = :not_found
      end

      ActiveSupport.on_load :action_view do
        require 'will_paginate/view_helpers/action_view'
        include WillPaginate::ViewHelpers::ActionView
      end
    end
  end
end
