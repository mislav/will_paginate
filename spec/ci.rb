#!/usr/bin/env ruby
databases = %w[ sqlite3 mysql mysql2 postgres ]
databases.delete 'mysql2' if ENV['BUNDLE_GEMFILE'].to_s.include? 'rails3.0'

def announce(name, msg)
  puts "\n\e[1;33m[#{name}] #{msg}\e[m\n"
end

def system(*args)
  puts "$ #{args.join(' ')}"
  super
end

if ENV['TRAVIS']
  system "mysql -e 'create database will_paginate;' >/dev/null"
  abort "failed to create mysql database" unless $?.success?
  system "psql -c 'create database will_paginate;' -U postgres >/dev/null"
  abort "failed to create postgres database" unless $?.success?
end

failed = false

for db in databases
  announce "DB", db
  ENV['DB'] = db
  failed = true unless system %(rake)
end

exit 1 if failed
