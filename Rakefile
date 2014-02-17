require "bundler/gem_tasks"

task :console do
  require 'irb'
  require 'bundler/setup'
  require_relative 'lib/resource_map_api_client'
  include ResourceMap

  ARGV.clear
  IRB.start
end
