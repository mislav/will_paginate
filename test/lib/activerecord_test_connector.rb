class ActiveRecordTestConnector
  cattr_accessor :able_to_connect
  cattr_accessor :connected

  # Set our defaults
  self.connected = false
  self.able_to_connect = true

  class << self
    def setup
      unless self.connected || !self.able_to_connect
        setup_connection
        load_schema
        require_fixture_models
        self.connected = true
      end
    rescue Exception => e  # errors from ActiveRecord setup
      $stderr.puts "\nSkipping ActiveRecord assertion tests: #{e}"
      #$stderr.puts "  #{e.backtrace.join("\n  ")}\n"
      self.able_to_connect = false
    end

    private

    def setup_connection
      if Object.const_defined?(:ActiveRecord)
        defaults = { :database => ':memory:' }
        # ActiveRecord::Base.logger = Logger.new STDOUT
        
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

    # Load actionpack sqlite tables
    def load_schema
      ActiveRecord::Base.silence do
        File.read(File.dirname(__FILE__) + "/../fixtures/schema.sql").split(';').each do |sql|
          ActiveRecord::Base.connection.execute(sql) unless sql.blank?
        end
      end
    end

    def require_fixture_models
      models = Dir.glob(File.dirname(__FILE__) + "/../fixtures/*.rb")
      models = (models.grep(/user.rb/) + models).uniq
      models.each {|f| require f}
    end
  end
end
