require 'will_paginate/view_helpers'

module WillPaginate
  module ViewHelpers
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.
    class LinkRendererBase

      # * +collection+ is a WillPaginate::Collection instance or any other object
      #   that conforms to that API
      # * +options+ are forwarded from +will_paginate+ view helper
      def prepare(collection, options)
        @collection = collection
        @options    = options

        # reset values in case we're re-using this instance
        @total_pages = @param_name = nil
      end
      
      def pagination
        items = @options[:page_links] ? windowed_page_numbers : []
        items.unshift :previous_page
        items.push :next_page
      end

    protected
    
      # Calculates visible page numbers using the <tt>:inner_window</tt> and
      # <tt>:outer_window</tt> options.
      def windowed_page_numbers
        inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i
        window_from = current_page - inner_window
        window_to = current_page + inner_window
        
        # adjust lower or upper limit if other is out of bounds
        if window_to > total_pages
          window_from -= window_to - total_pages
          window_to = total_pages
        end
        if window_from < 1
          window_to += 1 - window_from
          window_from = 1
          window_to = total_pages if window_to > total_pages
        end
        
        visible   = (1..total_pages).to_a
        left_gap  = (2 + outer_window)...window_from
        right_gap = (window_to + 1)...(total_pages - outer_window)
        
        # replace page numbers that shouldn't be visible with `:gap`
        [right_gap, left_gap].each do |gap|
          if (gap.last - gap.first) > 1
            visible -= gap.to_a
            visible.insert(gap.first - 1, :gap)
          end
        end
        
        visible
      end

    private

      def current_page
        @collection.current_page
      end

      def total_pages
        @collection.total_pages
      end

      def param_name
        @param_name ||= @options[:param_name].to_s
      end
    end
  end
end
