require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'

# prevent psych kicking in on 1.9 and interpreting
# local timestamps in fixtures as UTC
YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE

class ActiveRecordTestConnector
  cattr_accessor :able_to_connect
  cattr_accessor :connected

  FIXTURES_PATH = File.join(File.dirname(__FILE__), '..', 'fixtures')

  # Set our defaults
  self.connected = false
  self.able_to_connect = true

  def self.setup
    unless self.connected || !self.able_to_connect
      setup_connection
      load_schema
      add_load_path FIXTURES_PATH
      self.connected = true
    end
  rescue Exception => e  # errors from ActiveRecord setup
    $stderr.puts "\nSkipping ActiveRecord tests: #{e}\n\n"
    self.able_to_connect = false
  end

  private
  
  def self.add_load_path(path)
    dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
    autoload_paths = dep.respond_to?(:autoload_paths) ? dep.autoload_paths : dep.load_paths
    autoload_paths.unshift path
  end

  def self.setup_connection
    db = ENV['DB'].blank?? 'sqlite3' : ENV['DB']
    
    configurations = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'database.yml'))
    raise "no configuration for '#{db}'" unless configurations.key? db
    configuration = configurations[db]
    
    ActiveRecord::Base.logger = Logger.new(STDOUT) if $0 == 'irb'
    puts "using #{configuration['adapter']} adapter" unless ENV['DB'].blank?
    
    ActiveRecord::Base.establish_connection(configuration)
    ActiveRecord::Base.configurations = { db => configuration }
    ActiveRecord::Base.default_timezone = :local if ActiveRecord::Base.respond_to? :default_timezone
    prepare ActiveRecord::Base.connection

    unless Object.const_defined?(:QUOTED_TYPE)
      Object.send :const_set, :QUOTED_TYPE, ActiveRecord::Base.connection.quote_column_name('type')
    end
  end

  def self.load_schema
    ActiveRecord::Base.silence do
      ActiveRecord::Migration.verbose = false
      load File.join(FIXTURES_PATH, 'schema.rb')
    end
  end

  def self.prepare(conn)
    class << conn
      IGNORED_SQL = /
          ^(
            PRAGMA | SHOW\ max_identifier_length |
            SELECT\ (currval|CAST|@@IDENTITY|@@ROWCOUNT) |
            SHOW\ (FIELDS|TABLES)
          )\b |
          \bFROM\ (sqlite_master|pg_tables|pg_attribute)\b
        /x

      def execute_with_counting(sql, name = nil, &block)
        $query_count ||= 0
        $query_count  += 1 unless sql =~ IGNORED_SQL
        execute_without_counting(sql, name, &block)
      end

      alias_method_chain :execute, :counting
    end
  end
end
