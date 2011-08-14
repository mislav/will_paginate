begin
  require 'rspec/core/rake_task'
rescue LoadError
  # no spec tasks
else
  task :default => :spec

  desc 'Run ALL OF the specs'
  RSpec::Core::RakeTask.new(:spec) do |t|
    # t.ruby_opts = '-w'
    t.pattern = 'spec/finders/active_record_spec.rb' if ENV['DB'] and ENV['DB'] != 'sqlite3'
  end

  namespace :spec do
    desc "Run Rails specs"
    RSpec::Core::RakeTask.new(:rails) do |t|
      t.pattern = %w'spec/finders/active_record_spec.rb spec/view_helpers/action_view_spec.rb'
    end
  end
end

desc 'Run specs against both Rails 3.1 and Rails 3.0'
task :rails3 do |variable|
  system 'bundle exec rake spec && BUNDLE_GEMFILE=Gemfile.rails3.0 bundle exec rake spec:rails'
end
