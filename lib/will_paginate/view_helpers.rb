require 'will_paginate/deprecation'

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
  #   WillPaginate::ViewHelpers.pagination_options[:previous_label] = 'Previous page'
  #
  # By putting this into your environment.rb you can easily translate link texts to previous
  # and next pages, as well as override some other defaults to your liking.
  module ViewHelpers
    def self.pagination_options() @pagination_options; end
    def self.pagination_options=(value) @pagination_options = value; end
    
    self.pagination_options = {
      :class          => 'pagination',
      :previous_label => '&laquo; Previous',
      :next_label     => 'Next &raquo;',
      :inner_window   => 4, # links around the current page
      :outer_window   => 1, # links around beginning and end
      :separator      => ' ', # single space is friendly to spiders and non-graphic browsers
      :param_name     => :page,
      :params         => nil,
      :renderer       => 'WillPaginate::ViewHelpers::LinkRenderer',
      :page_links     => true,
      :container      => true
    }

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
end
