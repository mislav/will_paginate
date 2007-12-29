require 'will_paginate/core_ext'

module WillPaginate
  # A mixin for ActiveRecord::Base. Provides +per_page+ class method
  # and makes +paginate+ finders possible with some method_missing magic.
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
    # WillPaginate doesn't really add extra methods to your ActiveRecord models
    # (except +per_page+ unless it's already available). It simply intercepts
    # the calls to paginating finders such as +paginate+, +paginate_by_user_id+
    # (and so on) and translates them to ordinary finders: +find+,
    # +find_by_user_id+, etc. It does so with some +method_missing+ magic, but
    # you don't need to care for that. You simply use paginating finders same
    # way you used ordinary ones. You only need to specify what page do you want:
    #
    #   @posts = Post.paginate :page => params[:page]
    # 
    # In paginating finders, "all" is implicit. No sense in paginating a single
    # record, right? So:
    # 
    #   Post.paginate                  => Post.find :all
    #   Post.paginate_all_by_something => Post.find_all_by_something
    #   Post.paginate_by_something     => Post.find_all_by_something
    #
    # Don't forget to pass the +page+ parameter! Without it, paginating finders
    # will raise an error.
    #
    # == Options for paginating finders
    # * <tt>:page</tt> -- REQUIRED, but defaults to 1 if false or nil
    # * <tt>:per_page</tt> -- defaults to <tt>CurrentModel.per_page</tt> (which is 30 if not overridden)
    # * <tt>:total_entries</tt> -- use only if you manually count total entries
    # * <tt>:count</tt> -- additional options that are passed on to +count+
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
      # A query for counting rows will automatically be generated if you don't
      # supply <tt>:total_entries</tt>. If you experience problems with this
      # generated SQL, you might want to perform the count manually in your
      # application.
      # 
      def paginate_by_sql(sql, options)
        WillPaginate::Collection.create(*wp_parse_options!(options)) do |pager|
          query = sanitize_sql(sql)
          options.update :offset => pager.offset, :limit => pager.per_page
          
          original_query = query.dup
          add_limit! query, options
          # perfom the find
          pager.replace find_by_sql(query)
          
          unless pager.total_entries
            count_query = original_query.sub /\bORDER\s+BY\s+[\w`,\s]+$/mi, ''
            count_query = "SELECT COUNT(*) FROM (#{count_query}) AS count_table"
            # perform the count query
            pager.total_entries = count_by_sql(count_query)
          end
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

        options = args.pop
        page, per_page, total_entries = wp_parse_options!(options)
        # an array of IDs may have been given:
        total_entries ||= (Array === args.first and args.first.size)
        
        # paginate finders are really just find_* with limit and offset
        finder = method.to_s.sub /^paginate/, 'find'

        # :all is implicit
        if finder == 'find'
          args.unshift(:all) if args.empty?
        elsif finder.index('find_by_') == 0
          finder.sub! /^find/, 'find_all'
        end

        WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
          args << options.except(:count).merge(:offset => pager.offset, :limit => pager.per_page)
          pager.replace send(finder, *args)
          
          # magic counting for user convenience:
          pager.total_entries = wp_count!(options, args, finder) unless pager.total_entries
        end
      end

      def wp_count!(options, args, finder)
        excludees = [:count, :order, :limit, :offset]
        unless options[:select] and options[:select] =~ /^\s*DISTINCT/i
          excludees << :select # only exclude the select param if it doesn't begin with DISTINCT
        end
        # count expects (almost) the same options as find
        count_options = options.except *excludees

        # merge the hash found in :count
        # this allows you to specify :select, :order, or anything else just for the count query
        count_options.update(options.delete(:count) || {}) if options.key? :count

        # we may have to scope ...
        counter = Proc.new { count(count_options) }

        # we may be in a model or an association proxy!
        klass = (@owner and @reflection) ? @reflection.klass : self

        count = if finder =~ /^find_/ and klass.respond_to?(scoper = finder.sub(/^find_/, 'with_'))
                  # scope_out adds a 'with_finder' method which acts like with_scope, if it's present
                  # then execute the count with the scoping provided by the with_finder  
                  send(scoper, &counter)
                elsif conditions = wp_extract_finder_conditions(finder, args)
                  # extracted the conditions from calls like "paginate_by_foo_and_bar"
                  with_scope(:find => { :conditions => conditions }, &counter)
                else
                  counter.call
                end

        count.respond_to?(:length) ? count.length : count
      end

      def wp_parse_options!(options)
        raise ArgumentError, 'hash parameters expected' unless options.respond_to? :symbolize_keys!
        options.symbolize_keys!
        raise ArgumentError, ':page parameter required' unless options.key? :page
        
        if options[:count] and options[:total_entries]
          raise ArgumentError, ':count and :total_entries are mutually exclusive parameters'
        end

        page     = options.delete(:page) || 1
        per_page = options.delete(:per_page) || self.per_page
        total    = options.delete(:total_entries)
        [page, per_page, total]
      end

    private

      # thanks to active record for making us duplicate this code
      def wp_extract_finder_conditions(finder, arguments)
        return unless match = /^find_(all_by|by)_([_a-zA-Z]\w*)$/.match(finder.to_s)

        attribute_names = extract_attribute_names_from_match(match)
        unless all_attributes_exists?(attribute_names)
          raise "I can't make sense of `#{finder}`. Try doing the count manually"
        end
        construct_attributes_from_arguments(attribute_names, arguments)
      end
    end
  end
end
