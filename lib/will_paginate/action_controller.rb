require 'action_controller'

module WillPaginate
  ::ActionController::Base.class_eval do
    before_action :stop_default_if_will_paginate, only: :create

    def stop_default_if_will_paginate
      if will_paginate_post_request?
        index
        render :index
        return
      end
    end

    private

    def will_paginate_post_request?
      params[:will_paginate] == 'true'
    end
  end
end
