require 'will_paginate'
require 'will_paginate/collection'

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
    end

    def self.setup_actioncontroller
      ActionDispatch::ShowExceptions.rescue_responses['WillPaginate::InvalidPage'] = :not_found
    end

    def self.add_locale_path(config)
      locale_path = File.expand_path('../locale', __FILE__)
      config.i18n.railties_load_path.concat Dir["#{locale_path}/*.{rb,yml}"]
    end
  end
end
