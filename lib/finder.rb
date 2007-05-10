module WillPaginate
  # A mixin for ActiveRecord::Base. Provides `per_page` class method
  # and makes `paginate` finders possible with some method_missing magic.
  #
  module Finder
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :method_missing, :paginate
        define_method(:per_page) { 30 } unless respond_to? :per_page
      end
    end

    module ClassMethods
      def method_missing_with_paginate(method, *args, &block)
        # did somebody tried to paginate? if not, let them be
        unless method.to_s.index('paginate') == 0
          return method_missing_without_paginate(method, *args, &block) 
        end
        options = args.last.is_a?(Hash) ? args.pop.symbolize_keys : {}
        
        page = (options.delete(:page) || 1).to_i
        entries_per_page = options.delete(:per_page) || per_page

        total_entries = unless options[:total_entries]
          count_options = options.slice :conditions, :joins, :include, :order, :group, :select, :distinct
          count_options[:select] = options[:count] if options.key? :count
          count(count_options)
        else
          options.delete(:total_entries)
        end

        # oh, you're not so fun anymore!
        [:distinct, :count].each {|key| options.delete key } unless options.empty?
        
        finder = method.to_s.sub /^paginate/, 'find'
        # :all is implicit
        if finder == 'find'
          args.unshift(:all) if args.length < 2
        elsif finder !~ /^find_all/
          finder.sub! /^find/, 'find_all'
        end

        # do it!!
        args << options.merge(:offset => (page - 1) * entries_per_page, :limit => entries_per_page)
        entries = send finder, *args
        # wrap and return the package
        PaginatedCollection.new entries, page, entries_per_page, total_entries
      end
    end
  end

  # TODO: Controllers need love, too!
  # 
  # module ControllerHelpers
  #   def totally_awesome_helper
  #     patience
  #   end
  # end
end
