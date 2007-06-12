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

        finder = method.to_s.sub /^paginate/, 'find'
        # :all is implicit
        if finder == 'find'
          args.unshift(:all) if args.length < 2
        elsif finder.index('find_all') != 0
          finder.sub! /^find/, 'find_all'
        end

        # thanks to active record for making us duplicate this code
        options[:conditions] ||= wp_extract_finder_conditions(finder, args)

        # :total_entries and :count are mutually exclusive
        total_entries = unless options[:total_entries]
          count_options = options.slice :conditions, :joins, :include, :group, :distinct
          # merge the hash found in :count
          # this allows you to specify :select, :order, or anything else just for the count query
          count_options.update(options.delete(:count)) if options[:count]
          count = count(count_options)

          count.respond_to?(:length) ? count.length : count
        else
          options.delete(:total_entries)
        end

        returning WillPaginate::Collection.new(
            (options.delete(:page) || 1),
            (options.delete(:per_page) || per_page),
            total_entries
        ) do |pager|
          args << options.merge(:offset => pager.offset, :limit => pager.per_page)
          pager.replace(send(finder, *args))
        end
      end

      def wp_extract_finder_conditions(finder, arguments)
        return unless match = /^find_(all_by|by)_([_a-zA-Z]\w*)$/.match(finder.to_s)

        attribute_names = extract_attribute_names_from_match(match)
        raise StandardError, "I can't make sense of #{finder}" unless all_attributes_exists?(attribute_names)
        construct_attributes_from_arguments(attribute_names, arguments)
      end

      def respond_to?(method)
        case method.to_sym
        when :paginate, :paginate_by_sql
          true
        else
          super method.to_s.sub(/^paginate/, 'find')
        end
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
