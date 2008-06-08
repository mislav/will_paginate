require 'spec/rake/spectask'

spec_opts = 'spec/spec.opts'

desc 'Run all specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_opts = ['--options', spec_opts]
end

namespace :spec do
  desc 'Analyze spec coverage with RCov'
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--options', spec_opts]
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines('spec/rcov.opts').map { |l| l.chomp.split(" ") }.flatten
    end
  end
  
  desc 'Print Specdoc for all specs'
  Spec::Rake::SpecTask.new(:doc) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--format', 'specdoc', '--dry-run']
  end
  
  desc 'Generate HTML report'
  Spec::Rake::SpecTask.new(:html) do |t|
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--format', 'html:doc/spec_results.html', '--diff']
    t.fail_on_error = false
  end
end
