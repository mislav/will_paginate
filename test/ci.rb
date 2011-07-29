#!/usr/bin/env ruby
databases = %w[ sqlite3 mysql postgres ]
# skip mysql on 1.8.6 (doesn't work for unknown reason)
run_mysql = !(ENV['TRAVIS'] && RUBY_VERSION == '1.8.6')

def announce(name, msg)
  puts "\n\e[1;33m[#{name}] #{msg}\e[m\n"
end

def rails_version(gemfile)
  gemfile =~ /\d[\d.]*$/ ? $& : '2.3'
end

def system(*args)
  puts "$ #{args.join(' ')}"
  super
end

if ENV['TRAVIS']
  if run_mysql
    system "mysql -e 'create database will_paginate;' >/dev/null"
    abort "failed to create mysql database" unless $?.success?
  end
  system "psql -c 'create database will_paginate;' -U postgres >/dev/null"
  abort "failed to create postgres database" unless $?.success?
end

gemfiles = ['Gemfile']
gemfiles.concat Dir['test/gemfiles/*'].reject { |f| f.include? '.lock' }.sort.reverse

ruby19 = RUBY_VERSION > '1.9'
ruby19_gemfiles = gemfiles.first

bundler_options = ENV['TRAVIS'] ? "--path #{Dir.pwd}/vendor/bundle" : ''

failed = false

gemfiles.each do |gemfile|
  next if ruby19 and !ruby19_gemfiles.include? gemfile
  version = rails_version(gemfile)
  ENV['BUNDLE_GEMFILE'] = gemfile
  skip_install = gemfile == gemfiles.first
  if skip_install or system %(bundle install #{bundler_options})
    for db in databases
      next if 'mysql' == db and !run_mysql
      announce "Rails #{version}", "with #{db}"
      ENV['DB'] = db
      failed = true unless system %(bundle exec rake)
    end
  else
    # bundle install failed
    failed = true
  end
end

exit 1 if failed
