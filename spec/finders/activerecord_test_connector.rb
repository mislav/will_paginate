require 'active_record'
require 'active_record/fixtures'
require 'stringio'
require 'erb'

$query_count = 0
$query_sql = []

ignore_sql = /
    ^(
      PRAGMA | SHOW\ (max_identifier_length|search_path) |
      SELECT\ (currval|CAST|@@IDENTITY|@@ROWCOUNT) |
      SHOW\ ((FULL\ )?FIELDS|TABLES)
    )\b |
    \bFROM\ (sqlite_master|pg_tables|pg_attribute)\b
  /x

ActiveSupport::Notifications.subscribe(/^sql\./) do |*args|
  payload = args.last
  unless payload[:name] =~ /^Fixture/ or payload[:sql] =~ ignore_sql
    $query_count += 1
    $query_sql << payload[:sql]
  end
end

module ActiverecordTestConnector
  extend self
  
  attr_accessor :connected

  FIXTURES_PATH = File.expand_path('../../fixtures', __FILE__)

  # Set our defaults
  self.connected = false

  def setup
    unless self.connected
      setup_connection
      load_schema
      add_load_path FIXTURES_PATH
      self.connected = true
    end
  end

  private
  
  def add_load_path(path)
    dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
    dep.autoload_paths.unshift path
  end

  def setup_connection
    db = ENV['DB'].blank?? 'sqlite3' : ENV['DB']

    erb = ERB.new(File.read(File.expand_path('../../database.yml', __FILE__)))
    configurations = YAML.load(erb.result)
    raise "no configuration for '#{db}'" unless configurations.key? db
    configuration = configurations[db]
    
    # ActiveRecord::Base.logger = Logger.new(STDOUT) if $0 == 'irb'
    puts "using #{configuration['adapter']} adapter"
    
    ActiveRecord::Base.configurations = { db => configuration }
    ActiveRecord::Base.establish_connection(db.to_sym)
    ActiveRecord::Base.default_timezone = :utc
  end

  def load_schema
    begin
      $stdout = StringIO.new
      ActiveRecord::Migration.verbose = false
      load File.join(FIXTURES_PATH, 'schema.rb')
    ensure
      $stdout = STDOUT
    end
  end

  module FixtureSetup
    def fixtures(*tables)
      table_names = tables.map { |t| t.to_s }

      fixtures = ActiveRecord::FixtureSet.create_fixtures(ActiverecordTestConnector::FIXTURES_PATH, table_names)
      @@loaded_fixtures = {}
      @@fixture_cache = {}

      unless fixtures.nil?
        fixtures.each { |f| @@loaded_fixtures[f.table_name] = f }
      end

      table_names.each do |table_name|
        define_method(table_name) do |*names|
          @@fixture_cache[table_name] ||= {}

          instances = names.map do |name|
            if @@loaded_fixtures[table_name][name.to_s]
              @@fixture_cache[table_name][name] ||= @@loaded_fixtures[table_name][name.to_s].find
            else
              raise StandardError, "No fixture with name '#{name}' found for table '#{table_name}'"
            end
          end

          instances.size == 1 ? instances.first : instances
        end
      end
    end
  end
end
