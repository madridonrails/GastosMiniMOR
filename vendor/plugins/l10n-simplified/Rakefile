require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require File.join(File.dirname(__FILE__), 'version')


desc 'Default: run unit tests.'
task :default => :test

desc 'Test the l10n_simplified plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Create documentation for the l10n_simplified plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'LocalizationSimplified'
  rdoc.options << '--line-numbers' << '--inline-source' << '--charset=UTF-8'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/localization_simplified.rb')
  rdoc.rdoc_files.include('lib/lang_en.rb')
  #rdoc.rdoc_files.include('lib/**/*.rb')
end


# TODO: look at http://mandhro.com/2006/07/03/publising-rails-plug-ins-with-rake/
# that can probably also release to RubyForge
# TODO: the Hoe plugin can probably also do that 
# see http://seattlerb.rubyforge.org/hoe/ or
# http://drnicwilliams.com/2006/10/11/generating-new-gems/
desc 'Create release packages for the l10n_simplified plugin'
Rake::PackageTask.new("l10n-simplified", L10N_VERSION) do |p|
  p.need_tar = true
  p.need_zip = true
  p.package_files.include(["lib/**/*.rb", "*.rb", "MIT-LICENSE", "README"])
end

