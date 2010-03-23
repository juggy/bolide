require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rack/test'

namespace :test do
  Rake::TestTask.new(:name=>"test:rack") do |t|
    t.name = "rack"
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end
  Rake::Task["test:rack"].comment = "Run the Rack::Test tests in test"
end

task :test do
  Rake::Task["test:rack"].invoke
end