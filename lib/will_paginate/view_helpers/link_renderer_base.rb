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
        @total_pages = nil
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
        
        # these are always visible
        middle = window_from..window_to

        # left window
        if outer_window + 3 < middle.first # there's a gap
          left = (1..(outer_window + 1)).to_a
          left << :gap
        else # runs into visible pages
          left = 1...middle.first
        end

        # right window
        if total_pages - outer_window - 2 > middle.last # again, gap
          right = ((total_pages - outer_window)..total_pages).to_a
          right.unshift :gap
        else # runs into visible pages
          right = (middle.last + 1)..total_pages
        end
        
        out = left.to_a + middle.to_a + right.to_a
        return @options[:bisect] ? windowed_page_numbers_bisected( out ) : out  
      end

    
    def windowed_page_numbers_bisected(out)
        bisect_right = ((total_pages + current_page)/2).to_i
        bisect_left = (current_page/2).to_i
        inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i

        start_at = out.index(current_page)
        return out unless start_at
        start_at -= 1 while !out[start_at].is_a?(Symbol) && start_at > 0 
        window_from = start_at

        start_at = out.index(current_page)
        start_at += 1 while !out[start_at].is_a?(Symbol) && start_at < out.size 
        window_to = start_at 

        if !out.include?(bisect_right) && bisect_right < total_pages && bisect_right > 1
          out[window_to-2] = :gap
          out[window_to-1] =bisect_right  
        end 
        if !out.include?(bisect_left) && bisect_left > 1 
          out[ window_from + 1 ] = bisect_left
          out[ window_from + 2 ] = :gap
        end 
        return out
    end 

    private

      def current_page
        @collection.current_page
      end

      def total_pages
        @total_pages ||= @collection.total_pages
      end
    end
  end
end
