require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the will_paginate plugin.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.libs << 'test'
end

# I want to specify environment variables at call time
class EnvTestTask < Rake::TestTask
  attr_accessor :env

  def ruby(*args)
    env.each { |key, value| ENV[key] = value } if env
    super
    env.keys.each { |key| ENV.delete key } if env
  end
end

for configuration in %w( sqlite3 mysql postgres )
  EnvTestTask.new("test_#{configuration}") do |t|
    t.pattern = 'test/finder_test.rb'
    t.verbose = true
    t.env = { 'DB' => configuration }
    t.libs << 'test'
  end
end

task :test_databases => %w(test_mysql test_sqlite3 test_postgres)

desc %{Test everything on SQLite3, MySQL and PostgreSQL}
task :test_full => %w(test test_mysql test_postgres)

desc %{Test everything with Rails 1.2.x and 2.0.x gems}
task :test_all do
  all = Rake::Task['test_full']
  ENV['RAILS_VERSION'] = '~>1.2.6'
  all.invoke 
  # reset the invoked flag
  %w( test_full test test_mysql test_postgres ).each do |name|
    Rake::Task[name].instance_variable_set '@already_invoked', false
  end
  # do it again
  ENV['RAILS_VERSION'] = '~>2.0.2'
  all.invoke 
end

desc 'Generate RDoc documentation for the will_paginate plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  files = ['README.rdoc', 'LICENSE', 'CHANGELOG']
  files << FileList.new('lib/**/*.rb').
    exclude('lib/will_paginate/named_scope*').
    exclude('lib/will_paginate/array.rb').
    exclude('lib/will_paginate/version.rb')
    
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "will_paginate documentation"
  
  templates = %w[/Users/chris/ruby/projects/err/rock/template.rb /var/www/rock/template.rb]
  rdoc.template = templates.find { |t| File.exists? t }
  
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--inline-source'
  rdoc.options << '--charset=UTF-8'
  rdoc.options << '--webcvs=http://github.com/mislav/will_paginate/tree/master/'
end

task :manifest do
  list = Dir['**/*'].sort
  spec_file = Dir['*.gemspec'].first
  list -= [spec_file]
  
  File.read('.gitignore').each_line do |glob|
    glob = glob.chomp.sub(/^\//, '')
    list -= Dir[glob]
    list -= Dir["#{glob}/**/*"] if File.directory?(glob) and !File.symlink?(glob)
    puts "excluding #{glob}"
  end

  spec = File.read spec_file
  spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
    assignment = $1
    bunch = $2 ? list.grep(/^test\//) : list
    '%s%%w(%s)' % [assignment, bunch.join(' ')]
  end
    
  File.open(spec_file,   'w') {|f| f << spec }
  File.open('.manifest', 'w') {|f| f << list.join("\n") }
end

task :examples do
  %x(haml examples/index.haml examples/index.html)
  %x(sass examples/pagination.sass examples/pagination.css)
end

task :rcov do
  excludes = %w( lib/will_paginate/named_scope*
                 lib/will_paginate/core_ext.rb
                 lib/will_paginate.rb
                 rails* )
  
  system %[rcov -Itest:lib test/*.rb -x #{excludes.join(',')}]
end
