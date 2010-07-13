#!/usr/bin/env ruby
require 'rubygems' ;
require 'redis' ;

RDB = Redis.new(:host => 'localhost', :port => 6379)

start_time = Time.now.utc.to_f ;
iter=0;


$stdin.each do |line|
  _r, id, scat, sn, pr, fo, fr, st, fv, crat, sid, full = line.chomp.split("\t");
  iter+=1 ;
  break if iter > 20_000_000

  if (iter % 10_000 == 0)
    elapsed = (Time.now.utc.to_f - start_time)
    puts "%-20s\t%7d\t%7d\t%7.2f\t%7.2f" % [sn, fo, iter, elapsed, iter.to_f/elapsed]
  end

  RDB['sn:'+sn.downcase] = id unless sn.empty?
  RDB['sid:'+sid]        = id unless sid.empty?
  RDB['uid:'+id]         = [sn,sid,crat,scat].join(',') unless id.empty?
end
