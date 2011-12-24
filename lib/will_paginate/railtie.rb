require 'will_paginate'
require 'will_paginate/page_number'
require 'will_paginate/collection'
require 'will_paginate/i18n'

module WillPaginate
  class Railtie < Rails::Railtie
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

      # early access to ViewHelpers.pagination_options
      require 'will_paginate/view_helpers'
    end

    def self.setup_actioncontroller
      ( defined?(ActionDispatch::ExceptionWrapper) ?
        ActionDispatch::ExceptionWrapper : ActionDispatch::ShowExceptions
      ).send :include, ShowExceptionsPatch
      ActionController::Base.extend ControllerRescuePatch
    end

    def self.add_locale_path(config)
      config.i18n.railties_load_path.unshift(*WillPaginate::I18n.load_path)
    end

    # Extending the exception handler middleware so it properly detects
    # WillPaginate::InvalidPage regardless of it being a tag module.
    module ShowExceptionsPatch
      extend ActiveSupport::Concern
      included { alias_method_chain :status_code, :paginate }
      private
      def status_code_with_paginate
        if @exception.is_a?(WillPaginate::InvalidPage)
          Rack::Utils.status_code(:not_found)
        else
          status_code_without_paginate
        end
      end
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
