# encoding: utf-8
require 'rbconfig'
require File.expand_path('../lib/will_paginate/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = WillPaginate::VERSION::STRING

  s.summary = "Pagination plugin for web frameworks and other apps"
  s.description = "will_paginate provides a simple API for performing paginated queries with Active Record, DataMapper and Sequel, and includes helpers for rendering pagination links in Rails, Sinatra and Merb web apps."

  s.authors  = ['Mislav Marohnić']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'https://github.com/mislav/will_paginate/wiki'
  s.license  = 'MIT'

  s.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE']

  s.files = Dir['Rakefile', '{bin,lib,test,spec}/**/*', 'README*', 'LICENSE*']

  # include only files in version control
  git_dir = File.expand_path('../.git', __FILE__)
  void = defined?(File::NULL) ? File::NULL :
    RbConfig::CONFIG['host_os'] =~ /msdos|mswin|djgpp|mingw/ ? 'NUL' : '/dev/null'

  if File.directory?(git_dir) and system "git --version >>#{void} 2>&1"
    s.files &= `git --git-dir='#{git_dir}' ls-files -z`.split("\0")
  end

  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'actionpack'
  s.add_development_dependency 'rails-dom-testing'

  s.add_development_dependency 'rspec',   '~> 2.6.0'
  s.add_development_dependency 'mocha',   '~> 0.9.8'
  s.add_development_dependency 'sqlite3', '~> 1.3.6'
  s.add_development_dependency 'mysql',   '~> 2.9'
  s.add_development_dependency 'mysql2',  '~> 0.3.10'
  s.add_development_dependency 'pg',      '~> 0.11'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'wwtd'
end
