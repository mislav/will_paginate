require 'will_paginate/finders/base'
require 'data_mapper'

module WillPaginate::Finders
  module DataMapper
    include WillPaginate::Finders::Base

    protected
    
    def wp_query(options, pager, args, &block)
      find_options = options.except(:count).update(:offset => pager.offset, :limit => pager.per_page) 

      pager.replace all(find_options, &block)
      
      unless pager.total_entries
        pager.total_entries = wp_count(options) 
      end
    end

    # Does the not-so-trivial job of finding out the total number of entries
    # in the database. It relies on the ActiveRecord +count+ method.
    def wp_count(options, args, finder)
      excludees = [:count, :order, :limit, :offset, :readonly]
      count_options = options.except *excludees

      # merge the hash found in :count
      count_options.update options[:count] if options[:count]

      count_options.empty?? count() : count(count_options)
    end
  end
end

DataMapper::Base.class_eval do
  include WillPaginate::Finders::DataMapper
end
