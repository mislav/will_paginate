module WillPaginate
  module I18n
    def self.locale_dir
      File.expand_path('../locale', __FILE__)
    end

    def self.load_path
      Dir["#{locale_dir}/*.{rb,yml}"]
    end

    def will_paginate_translate(keys, options = {})
      if defined? ::I18n
        defaults = Array(keys).dup
        if block_given?
          if defined? ::I18n::Backend::Simple::MATCH
            # procs in defaults array were not supported back then
            defaults << yield(defaults.first, options)
          else
            defaults << Proc.new
          end
        end
        ::I18n.translate(defaults.shift, options.merge(:default => defaults, :scope => :will_paginate))
      else
        key = Array === keys ? keys.first : keys
        yield key, options
      end
    end
  end
end
