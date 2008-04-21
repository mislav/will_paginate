require 'will_paginate/core_ext'

module WillPaginate
  # = Will Paginate view helpers
  #
  # Currently there is only one view helper: +will_paginate+. It renders the
  # pagination links for the given collection. The helper itself is lightweight
  # and serves only as a wrapper around link renderer instantiation; the
  # renderer then does all the hard work of generating the HTML.
  # 
  # == Global options for helpers
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
    @@pagination_options = {
      :class        => 'pagination',
      :prev_label   => '&laquo; Previous',
      :next_label   => 'Next &raquo;',
      :inner_window => 4, # links around the current page
      :outer_window => 1, # links around beginning and end
      :separator    => ' ', # single space is friendly to spiders and non-graphic browsers
      :param_name   => :page,
      :params       => nil,
      :renderer     => 'WillPaginate::LinkRenderer',
      :page_links   => true,
      :container    => true
    }
    mattr_reader :pagination_options

    # Renders Digg/Flickr-style pagination for a WillPaginate::Collection
    # object. Nil is returned if there is only one page in total; no point in
    # rendering the pagination in that case...
    # 
    # ==== Options
    # * <tt>:class</tt> -- CSS class name for the generated DIV (default: "pagination")
    # * <tt>:prev_label</tt> -- default: "« Previous"
    # * <tt>:next_label</tt> -- default: "Next »"
    # * <tt>:inner_window</tt> -- how many links are shown around the current page (default: 4)
    # * <tt>:outer_window</tt> -- how many links are around the first and the last page (default: 1)
    # * <tt>:separator</tt> -- string separator for page HTML elements (default: single space)
    # * <tt>:param_name</tt> -- parameter name for page number in URLs (default: <tt>:page</tt>)
    # * <tt>:params</tt> -- additional parameters when generating pagination links
    #   (eg. <tt>:controller => "foo", :action => nil</tt>)
    # * <tt>:renderer</tt> -- class name of the link renderer (default: WillPaginate::LinkRenderer)
    # * <tt>:page_links</tt> -- when false, only previous/next links are rendered (default: true)
    # * <tt>:container</tt> -- toggles rendering of the DIV container for pagination links, set to
    #   false only when you are rendering your own pagination markup (default: true)
    # * <tt>:id</tt> -- HTML ID for the container (default: nil). Pass +true+ to have the ID automatically
    #   generated from the class name of objects in collection: for example, paginating
    #   ArticleComment models would yield an ID of "article_comments_pagination".
    #
    # All options beside listed ones are passed as HTML attributes to the container
    # element for pagination links (the DIV). For example:
    # 
    #   <%= will_paginate @posts, :id => 'wp_posts' %>
    #
    # ... will result in:
    #
    #   <div class="pagination" id="wp_posts"> ... </div>
    #
    # ==== Using the helper without arguments
    # If the helper is called without passing in the collection object, it will
    # try to read from the instance variable inferred by the controller name.
    # For example, calling +will_paginate+ while the current controller is
    # PostsController will result in trying to read from the <tt>@posts</tt>
    # variable. Example:
    #
    #   <%= will_paginate :id => true %>
    #
    # ... will result in <tt>@post</tt> collection getting paginated:
    #
    #   <div class="pagination" id="posts_pagination"> ... </div>
    #
    def will_paginate(collection = nil, options = {})
      options, collection = collection, nil if collection.is_a? Hash
      unless collection or !controller
        collection_name = "@#{controller.controller_name}"
        collection = instance_variable_get(collection_name)
        raise ArgumentError, "The #{collection_name} variable appears to be empty. Did you " +
          "forget to pass the collection object for will_paginate?" unless collection
      end
      # early exit if there is nothing to render
      return nil unless WillPaginate::ViewHelpers.total_pages_for_collection(collection) > 1
      
      options = options.symbolize_keys.reverse_merge WillPaginate::ViewHelpers.pagination_options
      # create the renderer instance
      renderer_class = options[:renderer].to_s.constantize
      renderer = renderer_class.new collection, options, self
      # render HTML for pagination
      renderer.to_html
    end
    
    # Wrapper for rendering pagination links at both top and bottom of a block
    # of content.
    # 
    #   <% paginated_section @posts do %>
    #     <ol id="posts">
    #       <% for post in @posts %>
    #         <li> ... </li>
    #       <% end %>
    #     </ol>
    #   <% end %>
    #
    # will result in:
    #
    #   <div class="pagination"> ... </div>
    #   <ol id="posts">
    #     ...
    #   </ol>
    #   <div class="pagination"> ... </div>
    #
    # Arguments are passed to a <tt>will_paginate</tt> call, so the same options
    # apply. Don't use the <tt>:id</tt> option; otherwise you'll finish with two
    # blocks of pagination links sharing the same ID (which is invalid HTML).
    def paginated_section(*args, &block)
      pagination = will_paginate(*args).to_s
      content = pagination + capture(&block) + pagination
      concat content, block.binding
    end

    # Renders a helpful message with numbers of displayed vs. total entries.
    # You can use this as a blueprint for your own, similar helpers.
    #
    #   <%= page_entries_info @posts %>
    #   #-> Displaying entries 6 - 10 of 26 in total
    def page_entries_info(collection)
      if collection.total_pages < 2
        case collection.size
        when 0; 'No entries found'
        when 1; 'Displaying <b>1</b> entry'
        else;   "Displaying <b>all #{collection.size}</b> entries"
        end
      else
        %{Displaying entries <b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b> in total} % [
          collection.offset + 1,
          collection.offset + collection.length,
          collection.total_entries
        ]
      end
    end

    def self.total_pages_for_collection(collection) #:nodoc:
      if collection.respond_to?('page_count') and !collection.respond_to?('total_pages')
        WillPaginate::Deprecation.warn <<-MSG
          You are using a paginated collection of class #{collection.class.name}
          which conforms to the old API of WillPaginate::Collection by using
          `page_count`, while the current method name is `total_pages`. Please
          upgrade yours or 3rd-party code that provides the paginated collection.
        MSG
        class << collection
          def total_pages; page_count; end
        end
      end
      collection.total_pages
    end
  end

  # This class does the heavy lifting of actually building the pagination
  # links. It is used by +will_paginate+ helper internally.
  class LinkRenderer
    # * +collection+ is a WillPaginate::Collection instance or any other object
    #   that conforms to that API
    # * +options+ are forwarded from +will_paginate+ view helper
    # * +template+ is the reference to the template being rendered
    def initialize(collection, options, template)
      @collection = collection
      @options    = options
      @template   = template
    end

    # Process it! This method returns the complete HTML string which contains
    # pagination links. Feel free to subclass LinkRenderer and change this
    # method as you see fit.
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.previous_page, %w(disabled prev_page), @options[:prev_label])
      links.push    page_link_or_span(@collection.next_page,     %w(disabled next_page), @options[:next_label])
      
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

    # The gap in page links is represented by:
    #
    #   <span class="gap">&hellip;</span>
    def gap_marker
      '<span class="gap">&hellip;</span>'
    end
    
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

    # Calculates visible page numbers using the <tt>:inner_window</tt> and
    # <tt>:outer_window</tt> options.
    def visible_page_numbers
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
      visible  -= left_gap.to_a  if left_gap.last - left_gap.first > 1
      visible  -= right_gap.to_a if right_gap.last - right_gap.first > 1

      visible
    end
    
    def page_link_or_span(page, span_class, text = nil)
      text ||= page.to_s
      classnames = Array[*span_class]
      
      if page and page != current_page
        @template.link_to text, url_for(page), :rel => rel_value(page), :class => classnames[1]
      else
        @template.content_tag :span, text, :class => classnames.join(' ')
      end
    end

    # Returns URL params for +page_link_or_span+, taking the current GET params
    # and <tt>:params</tt> option into account.
    def url_for(page)
      unless @url_string
        @url_params = { :escape => false }
        # page links should preserve GET parameters
        stringified_merge @url_params, @template.params if @template.request.get?
        stringified_merge @url_params, @options[:params] if @options[:params]
        
        if param_name.index(/[^\w-]/)
          page_param = (defined?(CGIMethods) ? CGIMethods : ActionController::AbstractRequest).
            parse_query_parameters("#{param_name}=#{page}")
          
          stringified_merge @url_params, page_param
        else
          @url_params[param_name] = page
        end

        url = @template.url_for(@url_params)
        @url_string = url.sub(%r!([?&/]#{CGI.escape param_name}[=/])#{page}!, '\1@')
        return url
      end
      @url_string.sub '@', page.to_s
    end

  private

    def rel_value(page)
      case page
      when @collection.previous_page; 'prev' + (page == 1 ? ' start' : '')
      when @collection.next_page; 'next'
      when 1; 'start'
      end
    end

    def current_page
      @collection.current_page
    end

    def total_pages
      @total_pages ||= WillPaginate::ViewHelpers.total_pages_for_collection(@collection)
    end

    def param_name
      @param_name ||= @options[:param_name].to_s
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
