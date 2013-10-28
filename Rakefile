# #Gem::manage_gems
# require 'rubygems/package_task' 

# spec = Gem::Specification.new do |s|
#     s.platform  =   Gem::Platform::RUBY
#     s.name      =   "rubypodder"
#     s.version   =   "1.0.0"
#     s.author    =   "Lex Miller"
#     s.email     =   "lex.miller @nospam@ gmail.com"
#     s.summary   =   "A podcast aggregator without an interface"
#     s.description   =   "A podcast aggregator without an interface, improved"
#     s.homepage   =   "https://github.com/zhum/rubypodder"
#     s.files     =   FileList['lib/*.rb', 'tests/*', 'Rakefile'].to_a
#     s.require_path       = "lib"
#     s.bindir             = "bin"
#     s.executables        = ["rubypodder"]
#     s.default_executable = "rubypodder"
#     s.add_dependency("rio")
#     s.add_dependency("rake")
#     s.add_dependency("mocha")
#     s.test_files         = Dir.glob('tests/*.rb')
#     s.has_rdoc           = true
#     s.extra_rdoc_files   = ["README", "MIT-LICENSE"]
# end
# Gem::PackageTask.new(spec) do |pkg|
#     pkg.need_tar = true
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rubypodder"
  gem.homepage = "http://github.com/zhum/rubypodder"
  gem.license = "BSD"
  gem.summary = %Q{Simple podcast aggregator}
  gem.description = %Q{Simple podcast aggregator with web interface}
  gem.email = "serg@parallel.ru"
  gem.authors = ["Lex Miller","Sergey Zhumatiy"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.libs << 'lib'
  t.test_files = FileList['tests/**/*_spec.rb']
  t.verbose = true
end

