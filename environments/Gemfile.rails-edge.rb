source 'https://rubygems.org'

gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: 'main'
gem 'actionpack',   git: 'https://github.com/rails/rails.git', branch: 'main'

gem 'thread_safe'

gem 'rspec', '~> 2.99'
gem 'mocha', '~> 0.9.8'

gem 'sqlite3', '~> 1.4.0'

gem 'mysql2', '~> 0.5.2', :group => :mysql
gem 'pg', '~> 1.2', :group => :pg
