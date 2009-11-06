require 'lib/will_paginate/version'

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = WillPaginate::VERSION::STRING
  s.date    = '2009-11-06'
  
  s.summary = "Adaptive pagination plugin for web frameworks and other applications"
  s.description = "The will_paginate library provides a simple, yet powerful and extensible API for pagination and rendering of page links in web application templates."
  
  s.authors  = ['Mislav Marohnić', 'PJ Hyett']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'http://github.com/mislav/will_paginate/wikis'
  
  s.has_rdoc = true
  s.rdoc_options = ['--main', 'README.rdoc', '--charset=UTF-8']
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc']
  
  s.files = Dir['Rakefile', '{bin,lib,rails,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files`.split("\n")
end
