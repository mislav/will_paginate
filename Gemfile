source 'https://rubygems.org'

rails_version = '~> 4.0.0'

gem 'activerecord', rails_version
gem 'actionpack',   rails_version

gem 'rspec', '~> 2.6.0'
gem 'mocha', '~> 0.9.8'

gem 'sqlite3', '~> 1.3.6'
gem 'sequel', '~> 3.8'
gem 'dm-core'
gem 'dm-aggregates'
gem 'dm-migrations'
gem 'dm-sqlite-adapter'
gem 'mongoid'

group :mysql do
  gem 'mysql', '~> 2.9'
  gem 'mysql2', '~> 0.3.10'
end
gem 'pg', '~> 0.11', :group => :pg

group :development do
  gem 'ruby-debug', :platforms => :mri_18
  gem 'debugger', :platforms => :mri_19
end
