require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => [:create_database, :test]

desc 'Test the will_paginate plugin.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs << 'test'
end

namespace :test do ||
  desc 'Test only Rails integration'
  Rake::TestTask.new(:rails) do |t|
    t.pattern = %w[test/finder_test.rb test/view_test.rb]
    t.libs << 'test'
  end

  desc 'Test only ActiveRecord integration'
  Rake::TestTask.new(:db) do |t|
    t.pattern = %w[test/finder_test.rb]
    t.libs << 'test'
  end
end

desc 'Create necessary databases'
task :create_database do |variable|
  case ENV['DB']
  when 'mysql', 'mysql2'
    `mysql -e 'create database will_paginate;'`
    abort "failed to create mysql database" unless $?.success?
  when 'postgres'
    `psql -c 'create database will_paginate;' -U postgres`
    abort "failed to create postgres database" unless $?.success?
  end
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
