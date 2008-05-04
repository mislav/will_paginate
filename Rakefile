require 'rubygems'
begin
  hanna_dir = '/home/mislav/projects/hanna/lib'
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
  rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'CHANGELOG').
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
  list = Dir['**/*'].sort
  spec_file = Dir['*.gemspec'].first
  list -= [spec_file] if spec_file
  
  File.read('.gitignore').each_line do |glob|
    glob = glob.chomp.sub(/^\//, '')
    list -= Dir[glob]
    list -= Dir["#{glob}/**/*"] if File.directory?(glob) and !File.symlink?(glob)
    puts "excluding #{glob}"
  end

  if spec_file
    spec = File.read spec_file
    spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
      assignment = $1
      bunch = $2 ? list.grep(/^test\//) : list
      '%s%%w(%s)' % [assignment, bunch.join(' ')]
    end
      
    File.open(spec_file,   'w') {|f| f << spec }
  end
  File.open('.manifest', 'w') {|f| f << list.join("\n") }
end

task :examples do
  %x(haml examples/index.haml examples/index.html)
  %x(sass examples/pagination.sass examples/pagination.css)
end
