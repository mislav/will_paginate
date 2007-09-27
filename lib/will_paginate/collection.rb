module WillPaginate
  # Arrays returned from paginating finds are, in fact, instances of this.
  # You may think of WillPaginate::Collection as an ordinary array with some
  # extra properties. Those properites are used by view helpers to generate
  # correct page links.
  #
  class Collection < Array
    attr_reader :current_page, :per_page, :total_entries

    # These collection objects are instantiated by ActiveRecord paginating
    # finders; there is no need to do it manually.
    #
    def initialize(page, per_page, total = nil)
      @current_page = page.to_i
      @per_page     = per_page.to_i
      
      self.total_entries = total if total
    end

    def self.create(page, per_page, total = nil, &block)
      pager = new(page, per_page, total)
      yield pager
      pager
    end

    # The total number of pages.
    def page_count
      @total_pages
    end

    # Current offset of the paginated collection. If we're on the first page,
    # it is always 0. If we're on the 2nd page and there are 30 entries per page,
    # the offset is 30. This property is useful if you want to render ordinals
    # besides your records: simply start with offset + 1.
    #
    def offset
      (current_page - 1) * per_page
    end

    # current_page - 1 or nil if there is no previous page
    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end

    # current_page + 1 or nil if there is no next page
    def next_page
      current_page < page_count ? (current_page + 1) : nil
    end

    def total_entries=(number)
      @total_entries = number.to_i
      @total_pages   = (@total_entries / per_page.to_f).ceil
    end

    def replace(array)
      super
      # The collection is shorter then page limit? Rejoice, because
      # then we know that we are on the last page!
      if total_entries.nil? and length < per_page
        self.total_entries = offset + length
      end
    end
  end
end
