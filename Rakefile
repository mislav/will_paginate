require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the will_paginate plugin.'
Rake::TestTask.new(:test) do |t|
  if ENV['DB'] and ENV['DB'] != 'sqlite3'
    t.pattern = %w[test/finder_test.rb]
  else
    t.pattern = 'test/**/*_test.rb'
  end
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
