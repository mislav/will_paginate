source 'https://rubygems.org'

rails_version = '~> 6.1.0'

gem 'activerecord', rails_version
gem 'actionpack',   rails_version

gem 'rspec', '~> 2.99'
gem 'mocha', '~> 0.9.8'

gem 'sqlite3', '~> 1.4.0'

gem 'mysql2', '~> 0.5.2', :group => :mysql
gem 'pg', '~> 1.2', :group => :pg
