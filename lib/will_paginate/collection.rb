module WillPaginate
  # Arrays returned from paginating finds are, in fact, instances of this.
  #
  class Collection < Array
    attr_reader :current_page, :per_page
    attr_accessor :total_entries

    def initialize(page, per_page, total)
      @current_page  = page.to_i
      @per_page      = per_page.to_i
      @total_entries = total.to_i
      @total_pages   = (@total_entries / @per_page.to_f).ceil
    end

    def page_count
      @total_pages
    end

    def offset
      (current_page - 1) * per_page
    end

    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end

    def next_page
      current_page < page_count ? (current_page + 1) : nil
    end
  end
end
