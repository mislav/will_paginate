require 'rubygems'
begin
  hanna_dir = '/Users/mislav/Projects/Hanna/lib'
  $:.unshift hanna_dir if File.exists? hanna_dir
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake'
  require 'rake/rdoctask'
end
load 'test/tasks.rake'

desc 'Default: run unit tests.'
task :default => :test

desc 'Generate RDoc documentation for the will_paginate plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'CHANGELOG.rdoc').
    include('lib/**/*.rb').
    exclude('lib/will_paginate/named_scope*').
    exclude('lib/will_paginate/array.rb').
    exclude('lib/will_paginate/version.rb')
  
  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "will_paginate documentation"
  
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--inline-source' << '--charset=UTF-8'
  rdoc.options << '--webcvs=http://github.com/mislav/will_paginate/tree/master/'
end

desc %{Update ".manifest" with the latest list of project filenames. Respect\
.gitignore by excluding everything that git ignores. Update `files` and\
`test_files` arrays in "*.gemspec" file if it's present.}
task :manifest do
  list = `git ls-files --full-name --exclude=*.gemspec --exclude=.*`.chomp.split("\n")
  
  if spec_file = Dir['*.gemspec'].first
    spec = File.read spec_file
    spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
      assignment = $1
      bunch = $2 ? list.grep(/^test\//) : list
      '%s%%w(%s)' % [assignment, bunch.join(' ')]
    end
      
    File.open(spec_file, 'w') { |f| f << spec }
  end
  File.open('.manifest', 'w') { |f| f << list.join("\n") }
end

task :examples do
  %x(haml examples/index.haml examples/index.html)
  %x(sass examples/pagination.sass examples/pagination.css)
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = 'tism-will_paginate'
  gem.date = Time.now.strftime('%Y-%m-%d')
  
  gem.summary = "Pagination for Rails"
  gem.description = "Relase to use https://github.com/tism/will_paginate/commit/adea61b139285357d72ae61e97bb49d709c20bb9"
  
  gem.authors = ['Mislav Marohnić', 'PJ Hyett']
  gem.email = 'mislav.marohnic@gmail.com'
  gem.homepage = 'http://github.com/mislav/will_paginate/wikis'
  
  gem.rubyforge_project = nil
  gem.has_rdoc = true
  gem.rdoc_options = ['--main', 'README.rdoc', '--charset=UTF-8']
  gem.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc']
  
  gem.files = Dir['Rakefile', '{bin,lib,rails,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end

