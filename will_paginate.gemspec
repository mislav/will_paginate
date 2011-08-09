# encoding: utf-8
require File.expand_path('../lib/will_paginate/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'will_paginate'
  gem.version = WillPaginate::VERSION::STRING
  
  gem.summary = "Easy pagination for Rails"
  gem.description = "will_paginate provides a simple API for Active Record pagination and rendering of pagination links in Rails templates."
  
  gem.authors  = ['Mislav Marohnić', 'PJ Hyett']
  gem.email    = 'mislav.marohnic@gmail.com'
  gem.homepage = 'https://github.com/mislav/will_paginate/wiki'
  
  gem.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']
  gem.extra_rdoc_files = ['README.md', 'LICENSE', 'CHANGELOG.rdoc']
  
  gem.files = Dir['Rakefile', '{bin,lib,rails,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
