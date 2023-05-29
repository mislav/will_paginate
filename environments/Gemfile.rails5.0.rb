source 'https://rubygems.org'

rails_version = '~> 5.0.7'

gem 'activerecord', rails_version
gem 'actionpack',   rails_version
gem 'rails-dom-testing'

gem 'rspec', '~> 3.12'
gem 'mocha', '~> 2.0'

gem 'sqlite3', '~> 1.3.6'

gem 'mysql2', '~> 0.5.2', :group => :mysql
gem 'pg', '~> 1.2.3', :group => :pg

# ruby 2.4 compat re: nokogiri
gem 'loofah', '< 2.21.0'
