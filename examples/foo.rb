#!/usr/bin/env ruby
$: << File.expand_path("~/ics/backend/configliere/lib")

require "wukong"

p Wukong::Script.new(nil,nil).options
p Wukong::Script.new(nil,nil).non_wukong_params

Wukong::Script.new(nil,nil).run
