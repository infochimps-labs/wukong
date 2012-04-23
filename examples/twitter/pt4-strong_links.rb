#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path("../../lib", File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'wukong/script'

require 'models'

Settings.use :commandline
Settings.resolve!

Wukong.flow(:mapper) do |input|
  source(:stdin) |
    from_tsv     | map{|arr| arr[3] } | from_json |
    map{|hsh| [ hsh['user_id'], hsh['strong_links'].sort_by{|id,wt| -wt }.map{|id,wt| id } ] } |
    reject{ |(id, links)| links.length < 5 } |
    project{|(id, links)| links[0..49].each{|link| emit([id, link]) unless link.to_i == 0 } } |
    to_tsv | stdout
end

Wukong::Script.new(Settings).run
