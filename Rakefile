require 'rspec/core/rake_task'

task :default => :spec

desc 'Run ALL OF the specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.skip_bundler = true
  # t.ruby_opts = '-w'
  t.pattern = 'spec/finders/active_record_spec.rb' if ENV['DB'] and ENV['DB'] != 'sqlite3'
end

namespace :spec do
  desc "Run Rails specs"
  RSpec::Core::RakeTask.new(:rails) do |t|
    t.skip_bundler = true
    t.pattern = %w'spec/finders/active_record_spec.rb spec/view_helpers/action_view_spec.rb'
  end
end
