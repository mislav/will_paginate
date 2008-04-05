require 'active_support'

# = You *will* paginate!
#
# First read about WillPaginate::Finder::ClassMethods, then see
# WillPaginate::ViewHelpers. The magical array you're handling in-between is
# WillPaginate::Collection.
#
# Happy paginating!
module WillPaginate
  class << self
    # shortcut for <tt>enable_actionpack; enable_activerecord</tt>
    def enable
      enable_actionpack
      enable_activerecord
    end
    
    # mixes in WillPaginate::ViewHelpers in ActionView::Base
    def enable_actionpack
      return if ActionView::Base.instance_methods.include? 'will_paginate'
      require 'will_paginate/view_helpers'
      ActionView::Base.class_eval { include ViewHelpers }

      if ActionController::Base.respond_to? :rescue_responses
        ActionController::Base.rescue_responses['WillPaginate::InvalidPage'] = :not_found
      end
    end
    
    # mixes in WillPaginate::Finder in ActiveRecord::Base and classes that deal
    # with associations
    def enable_activerecord
      return if ActiveRecord::Base.respond_to? :paginate
      require 'will_paginate/finder'
      ActiveRecord::Base.class_eval { include Finder }

      if patch_named_scope = !defined?(ActiveRecord::NamedScope)
        # bring in a Rails 2.1 feature
        require 'will_paginate/named_scope'

        ActiveRecord::Base.class_eval do
          include WillPaginate::NamedScope
        end
        
        ActiveRecord::Associations::AssociationProxy.class_eval do
          protected
          def with_scope(*args, &block)
            @reflection.klass.send :with_scope, *args, &block
          end
        end
      end

      # support pagination on associations
      [ ActiveRecord::Associations::AssociationCollection,
          ActiveRecord::Associations::HasManyThroughAssociation ].each do |klass|
        klass.class_eval do
          protected
          def method_missing(method, *args)
            if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
              if block_given?
                super { |*block_args| yield(*block_args) }
              else
                super
              end
            elsif @reflection.klass.scopes.include?(method)
              @reflection.klass.scopes[method].call(self, *args)
            else
              with_scope construct_scope do
                if block_given?
                  @reflection.klass.send(method, *args) { |*block_args| yield(*block_args) }
                else
                  @reflection.klass.send(method, *args)
                end
              end
            end
          end
        end if patch_named_scope
        
        klass.class_eval do
          include Finder::ClassMethods
          alias_method_chain :method_missing, :paginate
        end
      end

      ActiveRecord::Associations::HasAndBelongsToManyAssociation.class_eval do
        protected
        def method_missing(method, *args, &block)
          if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
            super
          elsif @reflection.klass.scopes.include?(method)
            @reflection.klass.scopes[method].call(self, *args)
          else
            @reflection.klass.with_scope(:find => { :conditions => @finder_sql, :joins => @join_sql, :readonly => false }) do
              @reflection.klass.send(method, *args, &block)
            end
          end
        end
      end if ActiveRecord::VERSION::MAJOR < 2 and patch_named_scope
    end
  end

  module Deprecation #:nodoc:
    extend ActiveSupport::Deprecation

    def self.warn(message, callstack = caller)
      message = 'WillPaginate: ' + message.strip.gsub(/\s+/, ' ')
      behavior.call(message, callstack) if behavior && !silenced?
    end

    def self.silenced?
      ActiveSupport::Deprecation.silenced?
    end
  end
end
