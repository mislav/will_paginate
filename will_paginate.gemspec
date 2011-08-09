# encoding: utf-8
require File.expand_path('../lib/will_paginate/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = WillPaginate::VERSION::STRING
  
  s.summary = "Pagination plugin for web frameworks and other apps"
  s.description = "will_paginate provides a simple API for performing paginated queries with Active Record, DataMapper and Sequel, and includes helpers for rendering pagination links in Rails, Sinatra and Merb web apps."
  
  s.authors  = ['Mislav Marohnić']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'https://github.com/mislav/will_paginate/wiki'
  
  s.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  
  s.files = Dir['Rakefile', '{bin,lib,test,spec}/**/*', 'README*', 'LICENSE*']
  s.files &= `git ls-files -z`.split("\0") if `type -t git 2>/dev/null || which git 2>/dev/null` && $?.success?
end
