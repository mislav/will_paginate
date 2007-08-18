module WillPaginate
  # A mixin for ActiveRecord::Base. Provides `per_page` class method
  # and makes `paginate` finders possible with some method_missing magic.
  #
  # Find out more in WillPaginate::Finder::ClassMethods
  #
  module Finder
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :method_missing, :paginate
        define_method(:per_page) { 30 } unless respond_to?(:per_page)
      end
    end

    # = Paginating finders for ActiveRecord models
    # 
    # WillPaginate doesn't really add extra methods to your ActiveRecord models (except +per_page+
    # unless it's already available). It simply intercepts
    # the calls to paginating finders such as +paginate+, +paginate_by_user_id+ (and so on) and
    # translates them to ordinary finders: +find+, +find_by_user_id+, etc. It does so with some
    # method_missing magic, but you don't need to care for that. You simply use paginating finders
    # same way you used ordinary ones. You only need to tell them what page you want in options.
    #
    #   @topics = Topic.paginate :all, :page => params[:page]
    # 
    # In paginating finders, "all" is implicit. No sense in paginating a single record, right? So:
    # 
    #   Post.paginate                  => Post.find :all
    #   Post.paginate_all_by_something => Post.find_all_by_something
    #   Post.paginate_by_something     => Post.find_all_by_something
    #
    # Knowing that, the above example can be written simply as:
    #
    #   @topics = Topic.paginate :page => params[:page]
    #
    # Don't forget to pass the +page+ parameter! Without it, paginating finders will raise an error.
    #
    # == Options
    # Options for paginating finders are:
    # 
    #   page           REQUIRED, but defaults to 1 if false or nil
    #   per_page       (default is read from the model, which is 30 if not overriden)
    #   total entries  not needed unless you want to count the records yourself somehow
    #   count          hash of options that are used only for the call to count
    # 
    module ClassMethods
      # This methods wraps +find_by_sql+ by simply adding LIMIT and OFFSET to your SQL string
      # based on the params otherwise used by paginating finds: +page+ and +per_page+.
      #
      # Example:
      # 
      #   @developers = Developer.paginate_by_sql ['select * from developers where salary > ?', 80000],
      #                           :page => params[:page], :per_page => 3
      # 
      def paginate_by_sql(sql, options)
        options, page, per_page = wp_parse_options!(options)
        sanitized_query = sanitize_sql(sql)
        total_entries = options[:total_entries] || count_by_sql("SELECT COUNT(*) FROM (#{sanitized_query}) AS count_table")

        returning WillPaginate::Collection.new(page, per_page, total_entries) do |pager|
          options.update :offset => pager.offset, :limit => pager.per_page
          add_limit! sanitized_query, options
          pager.replace find_by_sql(sanitized_query)
        end
      end

      def respond_to?(method, include_priv = false)
        case method.to_sym
        when :paginate, :paginate_by_sql
          true
        else
          super(method.to_s.sub(/^paginate/, 'find'), include_priv)
        end
      end

    protected
      
      def method_missing_with_paginate(method, *args, &block)
        # did somebody tried to paginate? if not, let them be
        unless method.to_s.index('paginate') == 0
          return method_missing_without_paginate(method, *args, &block) 
        end

        options, page, per_page = wp_parse_options!(args.pop)
        # paginate finders are really just find_* with limit and offset
        finder = method.to_s.sub /^paginate/, 'find'
        # magic counting for user convenience
        total_entries = wp_count!(options, args, finder)

        # :all is implicit
        if finder == 'find'
          args.unshift(:all) if args.empty?
        elsif finder.index('find_by_') == 0
          finder.sub! /^find/, 'find_all'
        end

        ::Object.returning WillPaginate::Collection.new(page, per_page, total_entries) do |pager|
          args << options.update(:offset => pager.offset, :limit => pager.per_page)
          pager.replace send(finder, *args)
        end
      end

      def wp_count!(options, args, finder)
        # :total_entries and :count are mutually exclusive!
        unless options[:total_entries]
          unless args.first.is_a? Array
            # count expects (almost) the same options as find
            count_options = options.except :count, :order, :select
            
            # merge the hash found in :count
            # this allows you to specify :select, :order, or anything else just for the count query
            count_options.update(options.delete(:count)) if options.key? :count
            # extract the conditions from calls like "paginate_by_foo_and_bar"
            conditions = wp_extract_finder_conditions(finder, args, count_options)

            # scope_out adds a 'with_finder' method which acts like with_scope, if it's present
            # then execute the count with the scoping provided by the with_finder  
            count = nil
            counter = Proc.new { count = count(count_options) }
            
            if respond_to?(scoper = finder.sub(/^find/, 'with'))
              send(scoper, &counter)
            else
              with_scope(:find => { :conditions => conditions }, &counter)
            end

            count.respond_to?(:length) ? count.length : count
          else
            # array of IDs was passed, so its size is the total number
            args.first.size
          end
        else
          options.delete(:total_entries)
        end
      end

      def wp_parse_options!(options)
        raise ArgumentError, 'hash parameters expected' unless options.respond_to? :symbolize_keys!
        options.symbolize_keys!
        raise ArgumentError, ':page parameter required' unless options.key? :page
        page = options.delete(:page) || 1
        per_page = options.delete(:per_page) || self.per_page
        [options, page, per_page]
      end

    private

      # thanks to active record for making us duplicate this code
      def wp_extract_finder_conditions(finder, arguments, count_options)
        return unless match = /^find_(all_by|by)_([_a-zA-Z]\w*)$/.match(finder.to_s)

        attribute_names = extract_attribute_names_from_match(match)
        raise "I can't make sense of #{finder}" unless all_attributes_exists?(attribute_names)
        construct_attributes_from_arguments(attribute_names, arguments)
      end
    end
  end
end
