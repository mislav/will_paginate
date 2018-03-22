require 'will_paginate/collection'

class Array
  # Paginates a static array (extracting a subset of it). The result is a
  # WillPaginate::Collection instance, which is an array with a few more
  # properties about its paginated state.
  #
  # Parameters:
  # * <tt>:page</tt> - current page, defaults to 1
  # * <tt>:per_page</tt> - limit of items per page, defaults to 30
  # * <tt>:total_entries</tt> - total number of items in the array, defaults to
  #   <tt>array.length</tt> (obviously)
  #
  # Example:
  #   arr = ['a', 'b', 'c', 'd', 'e']
  #   paged = arr.paginate(:per_page => 2)      #->  ['a', 'b']
  #   paged.total_entries                       #->  5
  #   arr.paginate(:page => 2, :per_page => 2)  #->  ['c', 'd']
  #   arr.paginate(:page => 3, :per_page => 2)  #->  ['e']
  #
  # This method was originally {suggested by Desi
  # McAdam}[http://www.desimcadam.com/archives/8] and later proved to be the
  # most useful method of will_paginate library.
  def paginate(options = {})
    page     = options[:page] || 1
    per_page = options[:per_page] || WillPaginate.per_page
    total    = options[:total_entries] || self.length

    WillPaginate::Collection.create(page, per_page, total) do |pager|
      pager.replace self[pager.offset, pager.per_page].to_a
    end
  end

  # Parameters:
  # * <tt>:page</tt> - current page, defaults to 1
  # * <tt>:total_entries</tt> - total number of items in the array, defaults to self.length
  #
  # Example:
  #   arr = ['a', 'b', 'c']
  #   arr.chunk_pagination(:page => 2, :total_entries => 10)  #->  [nil, nil, nil, 'a', 'b', 'c', nil, nil, nil, nil].paginate(:page => 2, :per_page => 3)
  #   arr.chunk_pagination(:page => 3, :total_entries => 3)  #->  []
  def chunk_pagination(options = {})
    page = options[:page] ? options[:page].to_i : 1
    per_page = self.length
    total_entries = options[:total_entries] ? options[:total_entries].to_i : self.length
    left_array = [nil]*(per_page * (page - 1))
    right_array = total_entries > per_page * page ? [nil]*(total_entries - per_page * page) : []
    self.unshift *left_array
    self.push *right_array
    self.paginate(:page => page, :per_page => per_page)
  end
end
