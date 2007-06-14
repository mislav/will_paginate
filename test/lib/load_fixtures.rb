dirname = File.dirname(__FILE__)
require File.join(dirname, '..', 'boot')
require File.join(dirname, 'activerecord_test_connector')

# setup the connection
ActiveRecordTestConnector.setup

# load all fixtures
fixture_path = File.join(dirname, '..', 'fixtures')
Fixtures.create_fixtures(fixture_path, ActiveRecord::Base.connection.tables)
