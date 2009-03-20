require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'

PKG_NAME           = "eload_select"
PKG_VERSION        = "0.0.1"
PKG_FILE_NAME      = "#{PKG_NAME}-#{PKG_VERSION}"
RUBY_FORGE_PROJECT = "eload_select"

spec = Gem::Specification.new do |s|
  s.name            = PKG_NAME
  s.version         = PKG_VERSION
  s.platform        = Gem::Platform::RUBY
  s.summary         = "Eager Loader Select Supporter forces :select to play nice with :include when eagerly loading ActiveRecord data with associations."
  s.files           = FileList["{lib,tasks}/**/*"].to_a + %w(init.rb LICENSE Rakefile README)
  s.require_path    = "lib"
  s.autorequire     = PKG_NAME
  s.has_rdoc        = true
  s.test_files      = nil
  s.add_dependency    "rails", ">= 1.2.0"
 
  s.author          = "Blythe Dunham"
  s.email           = "blythe@spongecell.com"
  s.homepage        = "http://spongetech.wordpress.com/"
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the ar_test plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << '.\lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the ar_test plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ArP'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end
 
desc "Publish the API docs and gem"
task :publish => [:pdoc, :release]

desc "Publish the release files to RubyForge."
task :release => [:gem, :package] do
  require 'rubyforge'
 
  options = {"cookie_jar" => RubyForge::COOKIE_F}
  options["password"] = ENV["RUBY_FORGE_PASSWORD"] if ENV["RUBY_FORGE_PASSWORD"]
  ruby_forge = RubyForge.new
  ruby_forge.login
 
  %w( gem tgz zip ).each do |ext|
    file = "pkg/#{PKG_FILE_NAME}.#{ext}"
    puts "Releasing #{File.basename(file)}..."
 
    ruby_forge.add_release(RUBY_FORGE_PROJECT, PKG_NAME, PKG_VERSION, file)
  end
end