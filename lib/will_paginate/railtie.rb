require 'will_paginate'
require 'will_paginate/page_number'
require 'will_paginate/collection'
require 'will_paginate/i18n'

module WillPaginate
  class Railtie < Rails::Railtie
    # Supported from Rails 3.2 forward.
    if config.action_dispatch.rescue_responses
      config.action_dispatch.rescue_responses["WillPaginate::InvalidPage"] = :not_found
    end

    initializer "will_paginate" do |app|
      ActiveSupport.on_load :active_record do
        require 'will_paginate/active_record'
      end

      ActiveSupport.on_load :action_controller do
        WillPaginate::Railtie.setup_actioncontroller
      end

      ActiveSupport.on_load :action_view do
        require 'will_paginate/view_helpers/action_view'
      end

      self.class.add_locale_path config

      # This is for Rails 3.0 and 3.1.
      unless app.config.action_dispatch.rescue_responses
        ActionDispatch::ShowExceptions.rescue_responses["WillPaginate::InvalidPage"] = :not_found
      end

      # Early access to ViewHelpers.pagination_options
      require 'will_paginate/view_helpers'
    end

    def self.setup_actioncontroller
      ActionController::Base.extend ControllerRescuePatch
    end

    def self.add_locale_path(config)
      config.i18n.railties_load_path.unshift(*WillPaginate::I18n.load_path)
    end

    module ControllerRescuePatch
      def rescue_from(*args, &block)
        if idx = args.index(WillPaginate::InvalidPage)
          args[idx] = args[idx].name
        end
        super(*args, &block)
      end
    end
  end
end
