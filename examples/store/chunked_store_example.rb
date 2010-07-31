#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'
# require 'wukong/store'

require 'configliere'
Configliere.use :commandline, :define, :config_file
Settings.read('foo.yaml')

# store = ChunkedFlatFileStore.new(Settings)

100.times do |iter|
  # store.save   [iter, Time.now.to_flat].join("\t")
  $stdout.puts [iter, Time.now.to_flat].join("\t")
  sleep 2
end


