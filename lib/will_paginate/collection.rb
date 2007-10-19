module WillPaginate
  # Arrays returned from paginating finds are, in fact, instances of this.
  # You may think of WillPaginate::Collection as an ordinary array with some
  # extra properties. Those properties are used by view helpers to generate
  # correct page links.
  #
  # WillPaginate::Collection also assists in rolling out your own pagination
  # solutions: see +create+.
  #
  class Collection < Array
    attr_reader :current_page, :per_page, :total_entries

    # Arguments to this constructor are the current page number, per-page limit
    # and the total number of entries. The last argument is optional because it
    # is best to do lazy counting; in other words, count *conditionally* after
    # populating the collection using the +replace+ method.
    #
    def initialize(page, per_page, total = nil)
      @current_page = page.to_i
      @per_page     = per_page.to_i
      
      self.total_entries = total if total
    end

    # Just like +new+, but yields the object after instantiation and returns it
    # afterwards. This is very useful for manual pagination:
    #
    #   @entries = WillPaginate::Collection.create(1, 10) do |pager|
    #     result = Post.find(:all, :limit => pager.per_page, :offset => pager.offset)
    #     # inject the result array into the paginated collection:
    #     pager.replace(result)
    #
    #     unless pager.total_entries
    #       # the pager didn't manage to guess the total count, do it manually
    #       pager.total_entries = Post.count
    #     end
    #   end
    #
    # The possibilities with this are endless. For another example, here is how
    # WillPaginate defines pagination on Array instances:
    #
    #   Array.class_eval do
    #     def paginate(page = 1, per_page = 15)
    #       WillPaginate::Collection.create(page, per_page, size) do |pager|
    #         pager.replace self[pager.offset, pager.per_page].to_a
    #       end
    #     end
    #   end
    #
    def self.create(page, per_page, total = nil, &block)
      pager = new(page, per_page, total)
      yield pager
      pager
    end

    # The total number of pages.
    def page_count
      @total_pages
    end

    # Helper method that is true when someone tries to fetch a page with a larger
    # number than the last page or with a number smaller than 1
    def out_of_bounds?
      current_page > page_count or current_page < 1
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

    # This is a magic wrapper for the original Array#replace method. It serves
    # for populating the paginated collection after initialization.
    #
    # Why magic? Because it tries to guess the total number of entries judging
    # by the size of given array. If it is shorter than +per_page+ limit, then we
    # know we're on the last page. This trick is very useful for avoiding
    # unnecessary hits to the database to do the counting after we fetched the
    # data for the current page.
    #
    # However, after using +replace+ you should always test the value of
    # +total_entries+ and set it to a proper value if it's +nil+. See the example
    # in +create+.
    def replace(array)
      returning super do
        # The collection is shorter then page limit? Rejoice, because
        # then we know that we are on the last page!
        if total_entries.nil? and length > 0 and length < per_page
          self.total_entries = offset + length
        end
      end
    end
  end
end
