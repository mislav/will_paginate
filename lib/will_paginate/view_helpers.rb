module WillPaginate
  module ViewHelpers
    # single space is friendly to spiders and non-graphic browsers
    PAGE_SEPARATOR = ' '

    # Renders Digg-style pagination. (We know you wanna!)
    # Returns nil if there is only one page in total (can't paginate that).
    # 
    # Options for will_paginate view helper:
    # 
    #   class:        CSS class name for the generated DIV (default "pagination")
    #   prev_label:   default '&laquo; Previous',
    #   next_label:   default 'Next &raquo;',
    #   inner_window: how many links are shown around the current page, defaults to 4
    #   outer_window: how many links are around the first and the last page, defaults to 1
    #
    # All extra options are passed to the generated container DIV, so eventually
    # they become its HTML attributes.
    #
    def will_paginate entries = @entries, options = {}
      total_pages = entries.page_count

      if total_pages > 1
        page = entries.current_page
        options = options.symbolize_keys.reverse_merge :class => 'pagination',
          :prev_label   => '&laquo; Previous',
          :next_label   => 'Next &raquo;',
          :inner_window => 4, # links around the current page
          :outer_window => 1 # links around beginning and end
        
        inner_window, outer_window = options.delete(:inner_window).to_i, options.delete(:outer_window).to_i
        min = page - inner_window
        max = page + inner_window
        
        # adjust lower or upper limit if other is out of bounds
        if max > total_pages then min -= max - total_pages
        elsif min < 1  then max += 1 - min
        end
        
        current   = min..max
        beginning = 1..(1 + outer_window)
        tail      = (total_pages - outer_window)..total_pages
        visible   = [current, beginning, tail].map(&:to_a).sum
        
        # build the list of the links
        links = (1..total_pages).inject([]) do |list, n|
          if visible.include? n
            list << page_link_or_span((n != page ? n : nil), 'current', n)
          elsif n == beginning.last + 1 || n == tail.first - 1
            # ellipsis represents the gap between windows
            list << '...'
          end
          list
        end
        
        # next and previous buttons
        links.unshift page_link_or_span(entries.previous_page, 'disabled', options.delete(:prev_label))
        links.push    page_link_or_span(entries.next_page,     'disabled', options.delete(:next_label))
        
        content_tag :div, links.join(options.delete(:separator) || PAGE_SEPARATOR), options
      end
    end
    
  protected

    def page_link_or_span(page, span_class = nil, text = page.to_s)
      unless page
        content_tag :span, text, :class => span_class
      else
        # page links should preserve GET parameters, so we merge params
        link_to text, params.merge(:page => (page !=1 ? page : nil))
      end
    end
  end
end
