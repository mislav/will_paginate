module WillPaginate
  # = Global options for pagination helpers
  #
  # Options for pagination helpers are optional and get their default values from the
  # WillPaginate::ViewHelpers.pagination_options hash. You can write to this hash to
  # override default options on the global level:
  #
  #   WillPaginate::ViewHelpers.pagination_options[:prev_label] = 'Previous page'
  #
  # By putting this into your environment.rb you can easily localize link texts to previous
  # and next pages, as well as override some other defaults to your liking.
  module ViewHelpers
    # default options that can be overriden on the global level
    @@pagination_options = { :class => 'pagination',
          :prev_label   => '&laquo; Previous',
          :next_label   => 'Next &raquo;',
          :inner_window => 4, # links around the current page
          :outer_window => 1, # links around beginning and end
          :separator    => ' ', # single space is friendly to spiders and non-graphic browsers
          :param_name   => :page
          }
    mattr_reader :pagination_options

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
    #   separator:    string separator for page HTML elements, default " " (single space)
    #   param_name:   parameter name for page number in URLs, defaults to "page"
    #
    # All extra options are passed to the generated container DIV, so eventually
    # they become its HTML attributes.
    #
    def will_paginate(entries = @entries, options = {})
      total_pages = entries.page_count

      if total_pages > 1
        options = options.symbolize_keys.reverse_merge(pagination_options)
        page, param = entries.current_page, options.delete(:param_name)
        
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
        visible   = [beginning, current, tail].map(&:to_a).flatten.sort.uniq
        links, prev = [], 0

        visible.each do |n|
          next if n < 1
          break if n > total_pages

          unless n - prev > 1
            prev = n
            links << page_link_or_span((n != page ? n : nil), 'current', n, param)
          else
            # ellipsis represents the gap between windows
            prev = n - 1
            links << '...'
            redo
          end
        end
        
        # next and previous buttons
        links.unshift page_link_or_span(entries.previous_page, 'disabled', options.delete(:prev_label), param)
        links.push    page_link_or_span(entries.next_page,     'disabled', options.delete(:next_label), param)
        
        content_tag :div, links.join(options.delete(:separator)), options
      end
    end
    
  protected

    def page_link_or_span(page, span_class, text, param)
      unless page
        content_tag :span, text, :class => span_class
      else
        # page links should preserve GET parameters, so we merge params
        link_to text, params.merge(param.to_sym => (page !=1 ? page : nil))
      end
    end
  end
end
