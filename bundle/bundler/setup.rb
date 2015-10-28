require 'rbconfig'
# ruby 1.8.7 doesn't define RUBY_ENGINE
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/i18n-0.7.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/multi_json-1.11.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/activesupport-3.2.21/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/builder-3.0.4/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/activemodel-3.2.21/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/erubis-2.7.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/journey-1.0.4/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rack-1.4.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rack-cache-1.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rack-test-0.6.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/hike-1.2.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/tilt-1.4.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/sprockets-2.2.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/actionpack-3.2.21/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/arel-3.0.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/tzinfo-0.3.44/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/activerecord-3.2.21/lib"
$:.unshift "#{path}/../../../lib"
