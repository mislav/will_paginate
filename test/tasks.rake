require 'rake/testtask'

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

task :rcov do
  excludes = %w( lib/will_paginate/named_scope*
                 lib/will_paginate/core_ext.rb
                 lib/will_paginate.rb
                 rails* )
  
  system %[rcov -Itest:lib test/*.rb -x #{excludes.join(',')}]
end
