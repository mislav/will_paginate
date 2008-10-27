module WillPaginate
  module ViewHelpers
    class LinkRenderer < LinkRendererBase
      
      # Overwrite the default generate_url method so will_paginate
      # can handle merb nested urls
      def generate_url(params, page)
        if @options[:base_url]
          "#{@options[:base_url]}?page=#{page}"
        else
          # soon to be replaced by @template.url(:this, :page => page)
          @template.url(@template.request.route.name, @template.request.params.except(:action, :controller).merge(:page => page))
        end
      end
      
    end
  end
end