require 'spec/rake/spectask'

spec_opts = 'spec/spec.opts'
spec_glob = FileList['spec/**/*_spec.rb']

desc 'Run all specs in spec directory'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_opts = ['--options', spec_opts]
  t.spec_files = spec_glob
end

namespace :spec do
  desc 'Run all specs in spec directory with RCov'
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--options', spec_opts]
    t.spec_files = spec_glob
    t.rcov = true
    # t.rcov_opts = lambda do
    #   IO.readlines('spec/rcov.opts').map {|l| l.chomp.split " "}.flatten
    # end
  end
  
  desc 'Print Specdoc for all specs'
  Spec::Rake::SpecTask.new(:doc) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--format', 'specdoc', '--dry-run']
    t.spec_files = spec_glob
  end
  
  desc 'Generate HTML report'
  Spec::Rake::SpecTask.new(:html) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--format', 'html:doc/spec_results.html', '--diff']
    t.spec_files = spec_glob
    t.fail_on_error = false
  end
end
