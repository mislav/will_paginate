require 'will_paginate/per_page'
require 'will_paginate/collection'
require 'active_record'

module WillPaginate
  # = Paginating finders for ActiveRecord models
  # 
  # WillPaginate adds +paginate+, +per_page+ and other methods to
  # ActiveRecord::Base class methods and associations.
  # 
  # In short, paginating finders are equivalent to ActiveRecord finders; the
  # only difference is that we start with "paginate" instead of "find" and
  # that <tt>:page</tt> is required parameter:
  #
  #   @posts = Post.paginate :all, :page => params[:page], :order => 'created_at DESC'
  #
  module ActiveRecord
    # In Rails, this is automatically called to mix-in pagination functionality to ActiveRecord.
    def self.setup
      ::ActiveRecord::Base.extend PerPage
      ::ActiveRecord::Base.extend ActiveRecord::Pagination
      ::ActiveRecord::Base.extend ActiveRecord::BaseMethods

      klasses = [::ActiveRecord::Relation]
      if defined? ::ActiveRecord::Associations::CollectionProxy
        klasses << ::ActiveRecord::Associations::CollectionProxy
      else
        klasses << ::ActiveRecord::Associations::AssociationCollection
      end

      # support pagination on associations and scopes
      klasses.each { |klass| klass.send(:include, ActiveRecord::Pagination) }
    end

    # makes a Relation look like WillPaginate::Collection
    module RelationMethods
      attr_accessor :current_page
      attr_writer :total_entries, :wp_count_options

      def per_page(value = nil)
        if value.nil? then limit_value
        else limit(value)
        end
      end

      # TODO: solve with less relation clones and code dups
      def limit(num)
        rel = super
        if rel.current_page
          rel.offset((rel.current_page-1) * rel.limit_value)
        else
          rel
        end
      end

      def offset(value = nil)
        if value.nil? then offset_value
        else super(value)
        end
      end

      def total_entries
        @total_entries ||= begin
          if loaded? and size < limit_value and (current_page == 1 or size > 0)
            offset_value + size
          else
            excluded = [:order, :limit, :offset]
            excluded << :includes unless eager_loading?
            rel = self.except(*excluded)
            # TODO: hack. decide whether to keep
            rel = rel.apply_finder_options(@wp_count_options) if defined? @wp_count_options
            @total_entries_queried = true
            rel.count
          end
        end
      end

      # workaround for Active Record 3.0
      def size
        if !loaded? and limit_value
          [super, limit_value].min
        else
          super
        end
      end

      def total_pages
        (total_entries / limit_value.to_f).ceil
      end

      def clone
        other = super
        other.current_page = current_page unless other.current_page
        other.total_entries = nil if defined? @total_entries_queried
        other
      end

      def to_a
        if current_page.nil? then super # workaround for Active Record 3.0
        else
          ::WillPaginate::Collection.create(current_page, limit_value) do |col|
            col.replace super
            col.total_entries ||= total_entries
          end
        end
      end
    end

    module Pagination
      def paginate(options)
        options  = options.dup
        pagenum  = options.fetch(:page) { raise ArgumentError, ":page parameter required" }
        per_page = options.delete(:per_page) || self.per_page
        total    = options.delete(:total_entries)

        count_options = options.delete(:count)
        options.delete(:page)

        rel = limit(per_page).page(pagenum)
        rel = rel.apply_finder_options(options) if options.any?
        rel.wp_count_options = count_options    if count_options
        rel.total_entries = total.to_i          unless total.blank?
        rel
      end

      def page(num)
        pagenum = num.nil? ? 1 : num.to_i
        raise ::WillPaginate::InvalidPage, num, pagenum if pagenum < 1
        rel = scoped.extending(RelationMethods)
        rel = rel.offset((pagenum-1) * (rel.limit_value || per_page))
        rel = rel.limit(per_page) unless rel.limit_value
        rel.current_page = pagenum
        rel
      end
    end

    module BaseMethods
      # Wraps +find_by_sql+ by simply adding LIMIT and OFFSET to your SQL string
      # based on the params otherwise used by paginating finds: +page+ and
      # +per_page+.
      #
      # Example:
      # 
      #   @developers = Developer.paginate_by_sql ['select * from developers where salary > ?', 80000],
      #                          :page => params[:page], :per_page => 3
      #
      # A query for counting rows will automatically be generated if you don't
      # supply <tt>:total_entries</tt>. If you experience problems with this
      # generated SQL, you might want to perform the count manually in your
      # application.
      # 
      def paginate_by_sql(sql, options)
        pagenum  = options.fetch(:page) { raise ArgumentError, ":page parameter required" }
        per_page = options[:per_page] || self.per_page
        total    = options[:total_entries]

        WillPaginate::Collection.create(pagenum, per_page, total) do |pager|
          query = sanitize_sql(sql.dup)
          original_query = query.dup
          # add limit, offset
          query << " LIMIT #{pager.per_page} OFFSET #{pager.offset}"
          # perfom the find
          pager.replace find_by_sql(query)

          unless pager.total_entries
            count_query = original_query.sub /\bORDER\s+BY\s+[\w`,\s]+$/mi, ''
            count_query = "SELECT COUNT(*) FROM (#{count_query})"

            unless self.connection.adapter_name =~ /^(oracle|oci$)/i
              count_query << ' AS count_table'
            end
            # perform the count query
            pager.total_entries = count_by_sql(count_query)
          end
        end
      end
    end
  end
end
