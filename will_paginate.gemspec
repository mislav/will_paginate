# encoding: utf-8
require 'rbconfig'
require File.expand_path('../lib/will_paginate/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = WillPaginate::VERSION::STRING
  s.required_ruby_version = '>= 2.0'
  
  s.summary = "Pagination plugin for web frameworks and other apps"
  s.description = "will_paginate provides a simple API for performing paginated queries with Active Record and Sequel, and includes helpers for rendering pagination links in Rails, Sinatra, and Hanami web apps."
  
  s.authors  = ['Mislav Marohnić']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'https://github.com/mislav/will_paginate'
  s.license  = 'MIT'
  
  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/mislav/will_paginate/issues',
    'changelog_uri'     => "https://github.com/mislav/will_paginate/releases/tag/v#{s.version}",
    'documentation_uri' => "https://www.rubydoc.info/gems/will_paginate/#{s.version}",
    'source_code_uri'   => "https://github.com/mislav/will_paginate/tree/v#{s.version}",
    'wiki_uri'          => 'https://github.com/mislav/will_paginate/wiki'
  }

  s.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  
  s.files = Dir['lib/**/*', 'README*', 'LICENSE*']

  # include only files in version control
  git_dir = File.expand_path('../.git', __FILE__)
  void = defined?(File::NULL) ? File::NULL :
    RbConfig::CONFIG['host_os'] =~ /msdos|mswin|djgpp|mingw/ ? 'NUL' : '/dev/null'

  if File.directory?(git_dir) and system "git --version >>#{void} 2>&1"
    s.files &= `git --git-dir='#{git_dir}' ls-files -z`.split("\0") 
  end
end
