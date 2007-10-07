require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'

class ActiveRecordTestConnector
  cattr_accessor :able_to_connect
  cattr_accessor :connected

  # Set our defaults
  self.connected = false
  self.able_to_connect = true

  def self.setup
    unless self.connected || !self.able_to_connect
      setup_connection
      load_schema
      # require_fixture_models
      Dependencies.load_paths.unshift(File.dirname(__FILE__) + "/../fixtures")
      self.connected = true
    end
  rescue Exception => e  # errors from ActiveRecord setup
    $stderr.puts "\nSkipping ActiveRecord assertion tests: #{e}"
    #$stderr.puts "  #{e.backtrace.join("\n  ")}\n"
    self.able_to_connect = false
  end

  private

  def self.setup_connection
    if Object.const_defined?(:ActiveRecord)
      defaults = { :database => ':memory:' }
      ActiveRecord::Base.logger = Logger.new STDOUT if $0 == 'irb'
      
      begin
        options = defaults.merge :adapter => 'sqlite3', :timeout => 500
        ActiveRecord::Base.establish_connection(options)
        ActiveRecord::Base.configurations = { 'sqlite3_ar_integration' => options }
        ActiveRecord::Base.connection
      rescue Exception  # errors from establishing a connection
        $stderr.puts 'SQLite 3 unavailable; trying SQLite 2.'
        options = defaults.merge :adapter => 'sqlite'
        ActiveRecord::Base.establish_connection(options)
        ActiveRecord::Base.configurations = { 'sqlite2_ar_integration' => options }
        ActiveRecord::Base.connection
      end

      unless Object.const_defined?(:QUOTED_TYPE)
        Object.send :const_set, :QUOTED_TYPE, ActiveRecord::Base.connection.quote_column_name('type')
      end
    else
      raise "Can't setup connection since ActiveRecord isn't loaded."
    end
  end

  def self.load_schema
    ActiveRecord::Base.silence do
      ActiveRecord::Migration.verbose = false
      load File.dirname(__FILE__) + "/../fixtures/schema.rb"
    end
  end

  def self.require_fixture_models
    models = Dir.glob(File.dirname(__FILE__) + "/../fixtures/*.rb")
    models = (models.grep(/user.rb/) + models).uniq
    models.each { |f| require f }
  end
end
