module Finder
  def self.included(base)
    base.extend ClassMethods
    class << base
      alias_method_chain :method_missing, :will_paginate
      define_method(:per_page) { 30 } unless respond_to? :per_page
    end
  end

  module ClassMethods
    def method_missing_with_will_paginate(method_id, *args, &block)
      unless match = /^paginate/.match(method_id.to_s)
        return method_missing_without_will_paginate(method_id, *args, &block) 
      end

      options = args.last.is_a?(Hash) ? args.pop : {}
      page    = options[:page].to_i.zero? ? 1 : options[:page].to_i
      options.delete(:page)
      args << options

      with_scope :find => { :offset => (page - 1) * per_page, :limit => per_page } do
        send(method_id.to_s.sub(/^paginate/, 'find'), *args)
      end
    end
  end
end