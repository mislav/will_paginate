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
      # based on the params otherwise used by paginating finds: +page+, +per_page+ and +total_entries+.
      # The last one is required because paginate_by_sql will not try to count by itself.
      #
      # Example:
      # 
      #   @developers = Developer.paginate_by_sql ['select * from developers where salary > ?', 80000],
      #                           :page => params[:page], :per_page => 3, :total_entries => 9
      # 
      def paginate_by_sql sql, options
        options, page, per_page = wp_parse_options options

        returning WillPaginate::Collection.new(page, per_page, options[:total_entries]) do |pager|
          options.update(:offset => pager.offset, :limit => pager.per_page)
          add_limit! (sql.is_a?(Array) ? sql.first : sql), options
          pager.replace find_by_sql(sql)
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

        options, page, per_page = wp_parse_options args.pop

        finder = method.to_s.sub /^paginate/, 'find'
        # :all is implicit
        if finder == 'find'
          args.unshift(:all) if args.empty?
        elsif finder.index('find_all') != 0
          finder.sub! /^find/, 'find_all'
        end

        # :total_entries and :count are mutually exclusive!
        total_entries = unless options[:total_entries]
          unless args.first.is_a? Array
            # count expects (almost) the same options as find
            count_options = options.reject { |key, value| key == :count or key == :order }
            # merge the hash found in :count
            # this allows you to specify :select, :order, or anything else just for the count query
            count_options.update(options.delete(:count)) if options[:count]
            # thanks to active record for making us duplicate this code
            count_options[:conditions] ||= wp_extract_finder_conditions(finder, args)

            count = count(count_options)
            count.respond_to?(:length) ? count.length : count
          else
            # array of IDs was passed, so its size is the total number
            args.first.size
          end
        else
          options.delete(:total_entries)
        end

        ::Object.returning WillPaginate::Collection.new(page, per_page, total_entries) do |pager|
          args << options.update(:offset => pager.offset, :limit => pager.per_page)
          pager.replace send(finder, *args)
        end
      end

      def wp_parse_options options
        raise ArgumentError, 'hash parameters expected' unless options.respond_to? :symbolize_keys!
        options.symbolize_keys!
        raise ArgumentError, ':page parameter required' unless options.key? :page
        page = options.delete(:page) || 1
        per_page = options.delete(:per_page) || self.per_page
        [options, page, per_page]
      end

    private

      def wp_extract_finder_conditions(finder, arguments)
        return unless match = /^find_(all_by|by)_([_a-zA-Z]\w*)$/.match(finder.to_s)

        attribute_names = extract_attribute_names_from_match(match)
        raise StandardError, "I can't make sense of #{finder}" unless all_attributes_exists?(attribute_names)
        construct_attributes_from_arguments(attribute_names, arguments)
      end
    end
  end
end
