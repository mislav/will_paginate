module WillPaginate
  module Finder
    def self.included(base)
      base.extend ClassMethods
      class << base
        define_method(:per_page) { 30 } unless respond_to? :per_page
      end
    end

    module ClassMethods
      def method_missing_with_will_paginate(method_id, *args, &block)
        unless match = /^paginate/.match(method_id.to_s)
          return method_missing_without_will_paginate(method_id, *args, &block) 
        end

        options = args.last.is_a?(Hash) ? args.pop : {}
        page    = (page = options.delete(:page).to_i).zero? ? 1 : page
        limit_per_page = options.delete(:per_page) || per_page
        args << options

        with_scope :find => { :offset => (page - 1) * limit_per_page, :limit => limit_per_page } do
          [send(method_id.to_s.sub(/^paginate/, 'find'), *args), page]
        end
      end
      alias_method_chain :method_missing, :will_paginate
    end
  end
end
