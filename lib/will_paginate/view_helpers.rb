# encoding: utf-8
require 'will_paginate/core_ext'

module WillPaginate
  # = Will Paginate view helpers
  #
  # The main view helper is +will_paginate+. It renders the pagination links
  # for the given collection. The helper itself is lightweight and serves only
  # as a wrapper around LinkRenderer instantiation; the renderer then does
  # all the hard work of generating the HTML.
  module ViewHelpers
    class << self
      # Write to this hash to override default options on the global level:
      #
      #   WillPaginate::ViewHelpers.pagination_options[:page_links] = false
      #
      attr_accessor :pagination_options
    end

    # default view options
    self.pagination_options = {
      :class          => 'pagination',
      :previous_label => nil,
      :next_label     => nil,
      :inner_window   => 4, # links around the current page
      :outer_window   => 1, # links around beginning and end
      :link_separator => ' ', # single space is friendly to spiders and non-graphic browsers
      :param_name     => :page,
      :params         => nil,
      :renderer       => nil,
      :page_links     => true,
      :container      => true
    }

    # Returns HTML representing page links for a WillPaginate::Collection-like object.
    # In case there is no more than one page in total, nil is returned.
    # 
    # ==== Options
    # * <tt>:class</tt> -- CSS class name for the generated DIV (default: "pagination")
    # * <tt>:previous_label</tt> -- default: "« Previous"
    # * <tt>:next_label</tt> -- default: "Next »"
    # * <tt>:page_links</tt> -- when false, only previous/next links are rendered (default: true)
    # * <tt>:inner_window</tt> -- how many links are shown around the current page (default: 4)
    # * <tt>:outer_window</tt> -- how many links are around the first and the last page (default: 1)
    # * <tt>:link_separator</tt> -- string separator for page HTML elements (default: single space)
    # * <tt>:param_name</tt> -- parameter name for page number in URLs (default: <tt>:page</tt>)
    # * <tt>:params</tt> -- additional parameters when generating pagination links
    #   (eg. <tt>:controller => "foo", :action => nil</tt>)
    # * <tt>:renderer</tt> -- class name, class or instance of a link renderer (default:
    #   <tt>WillPaginate::LinkRenderer</tt>)
    # * <tt>:page_links</tt> -- when false, only previous/next links are rendered (default: true)
    # * <tt>:container</tt> -- toggles rendering of the DIV container for pagination links, set to
    #   false only when you are rendering your own pagination markup (default: true)
    #
    # All options not recognized by will_paginate will become HTML attributes on the container
    # element for pagination links (the DIV). For example:
    # 
    #   <%= will_paginate @posts, :style => 'color:blue' %>
    #
    # will result in:
    #
    #   <div class="pagination" style="color:blue"> ... </div>
    #
    def will_paginate(collection, options = {})
      # early exit if there is nothing to render
      return nil unless collection.total_pages > 1

      options = WillPaginate::ViewHelpers.pagination_options.merge(options)

      scope = 'views.will_paginate'
      options[:previous_label] ||= will_paginate_translate(:previous_label, :scope => scope) { '&#8592; Previous' }
      options[:next_label]     ||= will_paginate_translate(:next_label, :scope => scope) { 'Next &#8594;' }

      # get the renderer instance
      renderer = case options[:renderer]
      when nil
        raise ArgumentError, ":renderer not specified"
      when String
        klass = if options[:renderer].respond_to? :constantize then options[:renderer].constantize
          else Object.const_get(options[:renderer]) # poor man's constantize
          end
        klass.new
      when Class then options[:renderer].new
      else options[:renderer]
      end
      # render HTML for pagination
      renderer.prepare collection, options, self
      renderer.to_html
    end

    # Renders a helpful message with numbers of displayed vs. total entries.
    # You can use this as a blueprint for your own, similar helpers.
    #
    #   <%= page_entries_info @posts %>
    #   #-> Displaying posts 6 - 10 of 26 in total
    #
    # By default, the message will use the humanized class name of objects
    # in collection: for instance, "project types" for ProjectType models.
    # Override this with the <tt>:entry_name</tt> parameter:
    #
    #   <%= page_entries_info @posts, :entry_name => 'item' %>
    #   #-> Displaying items 6 - 10 of 26 in total
    #
    # Entry name is entered in singular and pluralized with
    # <tt>String#pluralize</tt> method from ActiveSupport. If it isn't
    # loaded, specify plural with <tt>:plural_name</tt> parameter:
    #
    #   <%= page_entries_info @posts, :entry_name => 'item', :plural_name => 'items' %>
    #
    # By default, this method produces HTML output. You can trigger plain
    # text output by passing <tt>:html => false</tt> in options.
    def page_entries_info(collection, options = {})
      entry_name = options[:entry_name] || (collection.empty?? 'entry' :
                   collection.first.class.name.underscore.gsub('_', ' '))

      plural_name = if options[:plural_name]
        options[:plural_name]
      elsif entry_name == 'entry'
        plural_name = 'entries'
      elsif entry_name.respond_to? :pluralize
        plural_name = entry_name.pluralize
      else
        raise ArgumentError, "must provide :plural_name for #{entry_name.inspect}"
      end

      unless options[:html] == false
        b  = '<b>'
        eb = '</b>'
        sp = '&nbsp;'
        key = '_html'
      else
        b = eb = key = ''
        sp = ' '
      end

      scope = 'views.will_paginate.page_entries_info'

      if collection.total_pages < 2
        will_paginate_translate "single_page#{key}", :scope => scope, :count => collection.size,
          :name => entry_name, :plural => plural_name do |_, opts|
            case opts[:count]
            when 0; "No #{opts[:plural]} found"
            when 1; "Displaying #{b}1#{eb} #{opts[:name]}"
            else    "Displaying #{b}all #{opts[:count]}#{eb} #{opts[:plural]}"
            end
          end
      else
        will_paginate_translate "multi_page#{key}", :scope => scope, :total => collection.total_entries, :plural => plural_name,
          :from => collection.offset + 1, :to => collection.offset + collection.length do |_, opts|
            %{Displaying %s #{b}%d#{sp}-#{sp}%d#{eb} of #{b}%d#{eb} in total} %
              [ opts[:plural], opts[:from], opts[:to], opts[:total] ]
          end
      end
    end

    def will_paginate_translate(key, options = {})
      if defined? ::I18n
        ::I18n.translate(key, options.merge(:default => Proc.new))
      else
        yield key, options
      end
    end
  end
end
