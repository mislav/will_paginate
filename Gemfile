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
gem 'nokogiri', '~> 1.6.0' unless RUBY_VERSION >= '2.1.0'

if RUBY_VERSION < '2.0'
  gem 'public_suffix', '~> 1.4.5.0'
  gem 'addressable', '~> 2.3.0'
end

group :mysql do
  gem 'mysql', '~> 2.9'
  gem 'mysql2', '~> 0.3.10'
end
gem 'pg', '~> 0.18.4', :group => :pg

group :development do
  gem 'ruby-debug', :platforms => :mri_18
  gem 'debugger', :platforms => :mri_19
end
