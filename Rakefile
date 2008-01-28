require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the will_paginate plugin.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

for configuration in %w( sqlite3 mysql postgres )
  Rake::TestTask.new("test_#{configuration}") do |t|
    t.pattern = 'test/finder_test.rb'
    t.verbose = true
    t.options = "-- -#{configuration}"
  end
end

task :test_databases => %w(test_mysql test_sqlite3 test_postgres)
task :test_all => %w(test test_mysql test_postgres)

desc 'Generate RDoc documentation for the will_paginate plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  files = ['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "will_paginate"
  
  templates = %w[/Users/chris/ruby/projects/err/rock/template.rb /var/www/rock/template.rb]
  rdoc.template = templates.find { |t| File.exists? t }
  
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--inline-source'
  rdoc.options << '--charset=UTF-8'
end
