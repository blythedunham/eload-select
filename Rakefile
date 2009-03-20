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
  s.homepage        = "http://snowgiraffe.com/tech"
end



require 'rubygems'
require 'rake'
require 'rake/testtask'

DIR = File.dirname( __FILE__ )

task :default => [ "test:mysql" ]

task :boot do
  require File.expand_path( File.join( DIR, 'lib', 'ar-extensions' ) )
  require File.expand_path( File.join( DIR, 'tests', 'connections', "native_#{ENV['ARE_DB']}", 'connection' ) )
  require File.expand_path( File.join( DIR, 'db/migrate/version' ) )
end



ADAPTERS = %w(mysql)

namespace :test do
  namespace :activerecord do

    ADAPTERS.each do |adapter|
      desc "runs ActiveRecord unit tests for #{adapter} with ActiveRecord::Extensions"
      task adapter.to_sym do |t|
        activerecord_dir = ARGV[1]
        if activerecord_dir.nil? or ! File.directory?( activerecord_dir )
          STDERR.puts "ERROR: Pass in the path to ActiveRecord. Eg: /home/zdennis/rails_trunk/activerecord"
          exit
        end

        old_dir, old_env = Dir.pwd, ENV['RUBYOPT']
        Dir.chdir( activerecord_dir )
        ENV['RUBYOPT'] = "-r#{File.join(old_dir,'init.rb')}"

        load "Rakefile"
        Rake::Task[ "test_#{adapter}" ].invoke
        Dir.chdir( old_dir )
        ENV['RUBYOPT'] = old_env
      end
    end

  end

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