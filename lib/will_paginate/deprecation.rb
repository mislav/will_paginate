# borrowed from ActiveSupport::Deprecation
module WillPaginate
  module Deprecation
    mattr_accessor :debug
    self.debug = false

    # Choose the default warn behavior according to RAILS_ENV.
    # Ignore deprecation warnings in production.
    BEHAVIORS = {
      'test'        => Proc.new { |message, callstack|
                         $stderr.puts(message)
                         $stderr.puts callstack.join("\n  ") if debug
                       },
      'development' => Proc.new { |message, callstack|
                         logger = defined?(::RAILS_DEFAULT_LOGGER) ? ::RAILS_DEFAULT_LOGGER : Logger.new($stderr)
                         logger.warn message
                         logger.debug callstack.join("\n  ") if debug
                       }
    }

    def self.warn(message, callstack = caller)
      if behavior
        message = 'WillPaginate: ' + message.strip.gsub(/\s+/, ' ')
        behavior.call(message, callstack)
      end
    end

    def self.default_behavior
      if defined?(RAILS_ENV)
        BEHAVIORS[RAILS_ENV.to_s]
      else
        BEHAVIORS['test']
      end
    end

    # Behavior is a block that takes a message argument.
    mattr_accessor :behavior
    self.behavior = default_behavior

    def self.silence
      old_behavior = self.behavior
      self.behavior = nil
      yield
    ensure
      self.behavior = old_behavior
    end
  end
end
