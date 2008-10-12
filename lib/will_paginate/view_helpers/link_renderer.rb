require 'will_paginate/core_ext'
require 'will_paginate/view_helpers/link_renderer_base'

module WillPaginate
  module ViewHelpers
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.
    class LinkRenderer < LinkRendererBase
      
      def initialize
        @gap_marker = '<span class="gap">&hellip;</span>'
      end
      
      # * +collection+ is a WillPaginate::Collection instance or any other object
      #   that conforms to that API
      # * +options+ are forwarded from +will_paginate+ view helper
      # * +template+ is the reference to the template being rendered
      def prepare(collection, options, template)
        super(collection, options)
        @template = template
        # reset values in case we're re-using this instance
        @url_string = nil
      end

      # Process it! This method returns the complete HTML string which contains
      # pagination links. Feel free to subclass LinkRenderer and change this
      # method as you see fit.
      def to_html
        links = @options[:page_links] ? windowed_links : []
        # previous/next buttons
        links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
        links.push    page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])
        
        html = links.join(@options[:separator])
        @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
      end

      # Returns the subset of +options+ this instance was initialized with that
      # represent HTML attributes for the container element of pagination links.
      def html_attributes
        return @html_attributes if @html_attributes
        @html_attributes = @options.except *(WillPaginate::ViewHelpers.pagination_options.keys - [:class])
        # pagination of Post models will have the ID of "posts_pagination"
        if @options[:container] and @options[:id] === true
          @html_attributes[:id] = @collection.first.class.name.underscore.pluralize + '_pagination'
        end
        @html_attributes
      end
      
    protected

      # Collects link items for visible page numbers.
      def windowed_links
        prev = nil

        visible_page_numbers.inject [] do |links, n|
          # detect gaps:
          links << gap_marker if prev and n > prev + 1
          links << page_link_or_span(n, 'current')
          prev = n
          links
        end
      end

      def page_link_or_span(page, span_class, text = nil)
        text ||= page.to_s
        
        if page and page != current_page
          classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
          page_link page, text, :rel => rel_value(page), :class => classnames
        else
          page_span page, text, :class => span_class
        end
      end

      def page_link(page, text, attributes = {})
        @template.link_to text, url_for(page), attributes
      end

      def page_span(page, text, attributes = {})
        @template.content_tag :span, text, attributes
      end

      # Returns URL params for +page_link_or_span+, taking the current GET params
      # and <tt>:params</tt> option into account.
      def url_for(page)
        url_params = { :escape => false }
        # page links should preserve GET parameters
        stringified_merge url_params, @template.params if @template.request.get?
        stringified_merge url_params, @options[:params] if @options[:params]
        
        if complex = param_name.index(/[^\w-]/)
          page_param = (defined?(CGIMethods) ? CGIMethods : ActionController::AbstractRequest).
            parse_query_parameters("#{param_name}=#{page}")
          
          stringified_merge url_params, page_param
        else
          url_params[param_name] = page
        end

        @template.url_for url_params
      end

    private

      def rel_value(page)
        case page
        when @collection.previous_page; 'prev' + (page == 1 ? ' start' : '')
        when @collection.next_page; 'next'
        when 1; 'start'
        end
      end

      def stringified_merge(target, other)
        other.each do |key, value|
          key = key.to_s
          existing = target[key]

          if value.is_a?(Hash)
            target[key] = existing = {} if existing.nil?
            if existing.is_a?(Hash)
              stringified_merge(existing, value)
              return
            end
          end
          
          target[key] = value
        end
      end
    end
  end
end
