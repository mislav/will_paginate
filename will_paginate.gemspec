# encoding: utf-8
require File.expand_path('../lib/will_paginate/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = WillPaginate::VERSION::STRING
  
  s.summary = "Adaptive pagination plugin for web frameworks and other applications"
  s.description = "The will_paginate library provides a simple, yet powerful and extensible API for pagination and rendering of page links in web application templates."
  
  s.authors  = ['Mislav Marohnić']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'http://github.com/mislav/will_paginate/wikis'
  
  s.rdoc_options = ['--main', 'README.rdoc', '--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE', 'CHANGELOG.rdoc']
  
  s.files = Dir['Rakefile', '{bin,lib,test,spec}/**/*', 'README*', 'LICENSE*']
  s.files &= `git ls-files -z`.split("\0") if `type -t git 2>/dev/null || which git 2>/dev/null` && $?.success?
end
