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
      :renderer     => 'WillPaginate::LinkRenderer'
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
    # variable.
    #
    def will_paginate(collection = nil, options = {})
      unless collection or !controller
        collection_name = "@#{controller.controller_name}"
        collection = instance_variable_get(collection_name)
        raise ArgumentError, "The #{collection_name} variable appears to be empty. Did you " +
          "forget to specify the collection object for will_paginate?" unless collection
      end
      # early exit if there is nothing to render
      return nil unless collection.page_count > 1
      options = options.symbolize_keys.reverse_merge WillPaginate::ViewHelpers.pagination_options
      # create the renderer instance
      renderer_class = options[:renderer].to_s.constantize
      renderer = renderer_class.new collection, options, self
      # render HTML for pagination
      content_tag :div, renderer.to_html, renderer.html_attributes
    end
  end

  # This class does the heavy lifting of actually building the pagination
  # links. It is used by +will_paginate+ helper internally, but avoid using it
  # directly (for now) because its API is not set in stone yet.
  class LinkRenderer

    def initialize(collection, options, template)
      @collection = collection
      @options    = options
      @template   = template
    end

    def to_html
      returning windowed_paginator do |links|
        # next and previous buttons
        links.unshift page_link_or_span(@collection.previous_page, 'disabled', @options[:prev_label])
        links.push    page_link_or_span(@collection.next_page,     'disabled', @options[:next_label])
      end.join(@options[:separator])
    end

    def html_attributes
      @html_attributes ||= @options.except *(WillPaginate::ViewHelpers.pagination_options.keys - [:class])
    end
    
  protected

    def windowed_paginator
      inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i
      min = current_page - inner_window
      max = current_page + inner_window
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
          links << page_link_or_span((n != current_page ? n : nil), 'current', n)
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
      if page
        @template.link_to text, url_options(page)
      else
        @template.content_tag :span, text, :class => span_class
      end
    end

    def url_options(page)
      options = { param_name => page }
      # page links should preserve GET parameters
      options = params.merge(options) if @template.request.get?
      options.rec_merge!(@options[:params]) if @options[:params]
      return options
    end

  private

    def current_page
      @collection.current_page
    end

    def total_pages
      @collection.page_count
    end

    def param_name
      @param_name ||= @options[:param_name].to_sym
    end

    def params
      @params ||= @template.params.to_hash.symbolize_keys
    end
  end
end
