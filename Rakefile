require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

desc 'run tacks program'
task :run do
  sh 'bundle exec ruby tracks.rb'
end