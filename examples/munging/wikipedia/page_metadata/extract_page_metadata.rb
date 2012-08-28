#!/usr/bin/env ruby

require 'wukong'
require 'wukong/streamer/sql_streamer'

=begin
 Sample pig load statement:

  page_metadata = LOAD '$page_metadata' AS (id:int, namespace:int, title:chararray, 
    restrictions:chararray, counter:long, is_redirect:int, is_new:int, random:float, 
    touched:int, page_latest:int, len:int);
=end

module PageMetadataExtractor
  class Mapper < Wukong::Streamer::SQLStreamer
    #TODO: Add encoding guard
    columns [:int, :int, :string, :string, :int, 
             :int, :int, :float, :string, :int, :int]
   end
end

Wukong::Script.new(PageMetadataExtractor::Mapper, nil).run
