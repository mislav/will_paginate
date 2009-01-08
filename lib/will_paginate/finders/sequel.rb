require 'sequel'

existing_methods = Sequel::Dataset::Pagination.instance_methods

Sequel::Dataset::Pagination.module_eval do
  # it should quack like a WillPaginate::Collection
  
  alias :total_pages   :page_count  unless existing_methods.include? 'total_pages'
  alias :per_page      :page_size   unless existing_methods.include? 'per_page'
  alias :previous_page :prev_page   unless existing_methods.include? 'previous_page'
  alias :total_entries :pagination_record_count unless existing_methods.include? 'total_entries'
  
  def out_of_bounds?
    current_page > total_pages
  end

  # Current offset of the paginated collection
  def offset
    (current_page - 1) * per_page
  end
end