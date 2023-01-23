source 'https://rubygems.org'

gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: 'main'
gem 'actionpack',   git: 'https://github.com/rails/rails.git', branch: 'main'

gem 'thread_safe'

gem 'rspec', '~> 3.12'
gem 'mocha', '~> 2.0'

gem 'sqlite3', '~> 1.4.0'

gem 'mysql2', '~> 0.5.2', :group => :mysql
gem 'pg', '~> 1.2', :group => :pg
