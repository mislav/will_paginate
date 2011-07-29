#!/usr/bin/env ruby
databases = %w[ sqlite3 mysql postgres ]

def announce(name, msg)
  puts "\n\e[1;33m[#{name}] #{msg}\e[m\n"
end

def rails_version(gemfile)
  gemfile =~ /\d[\d.]*$/ ? $& : '2.3'
end

if ENV['TRAVIS']
  system "mysql -e 'create database will_paginate;' >/dev/null"
  abort "failed to create mysql database" unless $?.success?
  system "psql -c 'create database will_paginate;' -U postgres >/dev/null"
  abort "failed to create postgres database" unless $?.success?
end

gemfiles = ['Gemfile']
gemfiles.concat Dir['test/gemfiles/*'].reject { |f| f.include? '.lock' }.sort.reverse

ruby19 = RUBY_VERSION > '1.9'
ruby19_gemfiles = gemfiles.first

bundler_options = ENV['TRAVIS'] ? '--path vendor/bundle' : ''

failed = false

gemfiles.each do |gemfile|
  next if ruby19 and !ruby19_gemfiles.include? gemfile
  ENV['BUNDLE_GEMFILE'] = gemfile
  if system %(bundle install #{bundler_options})
    for db in databases
      announce "Rails #{rails_version(gemfile)}", "with #{db}"
      ENV['DB'] = db
      failed = true unless system %(bundle exec rake)
    end
  end
end

exit 1 if failed
