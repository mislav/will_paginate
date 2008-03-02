require 'rubyforge'
require 'rake/gempackagetask'
require 'lib/will_paginate/version.rb'

RUBYFORGE_NAME = 'will-paginate'
NAME = 'will_paginate'
version = WillPaginate::VERSION::STRING

DESCRIPTION = <<-DESC
  A Rails plugin that provides pagination solutions
  for querying models and rendering pagination links in views.
DESC
DESCRIPTION.strip!.gsub! /\s+/, ' '

changes = nil

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = version
  s.summary = s.description = DESCRIPTION
  s.authors = ['Mislav Marohnić', 'PJ Hyett']
  s.email = 'mislav.marohnic@gmail.com'
  s.homepage = 'http://github.com/mislav/will_paginate/wikis'
  s.rubyforge_project = RUBYFORGE_NAME

  s.add_dependency 'activesupport', '>=1.4.4'

  s.files = File.read("Manifest.txt").split("\n")
  s.executables = s.files.grep(/^bin/) { |f| File.basename(f) }

  s.bindir = "bin"
  dirs = Dir['{lib,ext}']
  s.require_paths = dirs unless dirs.empty?

  s.rdoc_options = ['--main', 'README', '--inline-source', '--charset=UTF-8']
  s.extra_rdoc_files = %w(README LICENSE) # + s.files.grep(/\.txt$/) - %w(Manifest.txt)
  s.has_rdoc = true
end

Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end

desc 'Package and upload the release to rubyforge.'
task :release => [:clean, :package] do |t|
  v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
  abort "Version doesn't match #{version}" if v != version
  files = Dir["pkg/#{NAME}-#{version}.*"]

  rf = RubyForge.new
  puts "Logging in to RubyForge"
  rf.login

  c = rf.userconfig
  c["release_notes"] = DESCRIPTION
  c["release_changes"] = changes if changes
  c["preformatted"] = true

  puts "Releasing #{NAME} v. #{version}"
  p files
  rf.add_release RUBYFORGE_NAME, NAME, version, *files
end

task :clean => [ :clobber_rdoc, :clobber_package ] do
  removed = []
  %w(diff diff.txt email.txt ri *.gem **/*~ **/.DS_Store).each do |pattern|
    files = Dir[pattern]
    next if files.empty?
    FileUtils.rm_rf files
    removed.concat files
  end
  puts "Removed files: #{removed.inspect}" unless removed.empty?
end

# desc 'Upload website files to rubyforge'
# task :website_upload do
#   host = "#{rubyforge_username}@rubyforge.org"
#   remote_dir = "/var/www/gforge-projects/#{PATH}/"
#   local_dir = 'website'
#   sh %{rsync -aCv #{local_dir}/ #{host}:#{remote_dir}}
# end
