require 'will_paginate/core_ext'

module WillPaginate
  # = Global options for pagination helpers
  #
  # Options for pagination helpers are optional and get their default values from the
  # WillPaginate::ViewHelpers.pagination_options hash. You can write to this hash to
  # override default options on the global level:
  #
  #   WillPaginate::ViewHelpers.pagination_options[:prev_label] = 'Previous page'
  #
  # By putting this into your environment.rb you can easily translate link texts to previous
  # and next pages, as well as override some other defaults to your liking.
  module ViewHelpers
    # default options that can be overridden on the global level
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
      total_pages = 

      if entries.page_count > 1
        renderer = WillPaginate::LinkRenderer.new entries, options, self
        links = renderer.items
        
        content_tag :div, links, renderer.html_options
      end
    end
  end

  # This class does the heavy lifting of actually building the pagination
  # links. It is used by +will_paginate+ helper internally, but avoid using it
  # directly (for now) because its API is not set in stone yet.
  class LinkRenderer

    def initialize(collection, options, template)
      @collection = collection
      @options = options.symbolize_keys.reverse_merge WillPaginate::ViewHelpers.pagination_options
      @template = template
    end

    def items
      returning windowed_paginator do |links|
        # next and previous buttons
        links.unshift page_link_or_span(@collection.previous_page, 'disabled', @options[:prev_label])
        links.push    page_link_or_span(@collection.next_page,     'disabled', @options[:next_label])
      end.join(@options[:separator])
    end

    def html_options
      @options.except *(WillPaginate::ViewHelpers.pagination_options.keys - [:class])
    end
    
  protected

    def windowed_paginator
      inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i
      min = page - inner_window
      max = page + inner_window
      # adjust lower or upper limit if other is out of bounds
      if max > total_pages then min -= max - total_pages
      elsif min < 1 then max += 1 - min
      end
      
      current   = min..max
      beginning = 1..(1 + outer_window)
      tail      = (total_pages - outer_window)..total_pages
      visible   = [beginning, current, tail].map(&:to_a).flatten.sort.uniq
      
      links, prev = [], 0

      visible.each do |n|
        next  if n < 1
        break if n > total_pages

        unless n - prev > 1
          prev = n
          links << page_link_or_span((n != page ? n : nil), 'current', n)
        else
          # ellipsis represents the gap between windows
          prev = n - 1
          links << '...'
          redo
        end
      end
      
      links
    end

    def page_link_or_span(page, span_class, text)
      unless page
        @template.content_tag :span, text, :class => span_class
      else
        # page links should preserve GET/POST parameters
        @template.link_to text, @template.params.merge(param => page != 1 ? page : nil)
      end
    end

  private

    def page
      @collection.current_page
    end

    def total_pages
      @collection.page_count
    end

    def param
      @options[:param_name].to_sym
    end
  end
end
