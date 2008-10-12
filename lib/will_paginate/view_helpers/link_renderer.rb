require 'will_paginate/core_ext'
require 'will_paginate/view_helpers/link_renderer_base'

module WillPaginate
  module ViewHelpers
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.
    class LinkRenderer < LinkRendererBase
      
      # * +collection+ is a WillPaginate::Collection instance or any other object
      #   that conforms to that API
      # * +options+ are forwarded from +will_paginate+ view helper
      # * +template+ is the reference to the template being rendered
      def prepare(collection, options, template)
        super(collection, options)
        @template = template
        @html_attributes = nil
      end

      # Process it! This method returns the complete HTML string which contains
      # pagination links. Feel free to subclass LinkRenderer and change this
      # method as you see fit.
      def to_html
        links = pagination.map do |item|
          item.is_a?(Fixnum) ? page_number(item) : send(item)
        end
        
        html = links.join(@options[:separator])
        @options[:container] ? tag(:div, html, html_attributes) : html
      end

      # Returns the subset of +options+ this instance was initialized with that
      # represent HTML attributes for the container element of pagination links.
      def html_attributes
        @html_attributes ||= begin
          attributes = @options.except *(WillPaginate::ViewHelpers.pagination_options.keys - [:class])
          # pagination of Post models will have the ID of "posts_pagination"
          if @options[:container] and @options[:id] === true
            attributes[:id] = @collection.first.class.name.underscore.pluralize + '_pagination'
          end
          attributes
        end
      end
      
    protected
    
      def page_number(page)
        unless page == current_page
          link page, page, :rel => rel_value(page)
        else
          tag :span, page, :class => 'current'
        end
      end
      
      def gap
        '<span class="gap">&hellip;</span>'
      end
      
      def previous_page
        previous_or_next_page(@collection.previous_page, @options[:previous_label], 'prev_page')
      end
      
      def next_page
        previous_or_next_page(@collection.next_page, @options[:next_label], 'next_page')
      end
      
      def previous_or_next_page(page, text, classname)
        if page
          link text, page, :class => classname
        else
          tag :span, text, :class => classname + ' disabled'
        end
      end
      
      def link(text, target, attributes = {})
        if target.is_a? Fixnum
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        tag(:a, text, attributes)
      end
      
      def tag(name, value, attributes = {})
        string_attributes = attributes.inject('') do |str, pair|
          unless pair.last.nil?
            str << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
          end
          str
        end
        "<#{name}#{string_attributes}>#{value}</#{name}>"
      end

      # Returns URL params for +page_link_or_span+, taking the current GET params
      # and <tt>:params</tt> option into account.
      def url(page)
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
