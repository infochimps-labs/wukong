#!/usr/bin/env ruby

require 'wukong'
module PageviewsToTSV
  class Mapper < Wukong::Streamer::LineStreamer

# change spaces to tabs
# un-urlencode names
# change namespace name to number
=begin
  NAMESPACES = {
    "Main" => 0,"" => 0,"Talk" => 1,
    "User" => 2,"User_Talk" => 3,
    "Wikipedia" => 4, "Wikipedia_talk" => 5,
    "File" => 6,"File_talk" => 7,
    "MediaWiki" => 8,"MediaWiki_talk" => 9,
    "Template" => 10,"Template_talk" => 11,
    "Help" => 12,"Help_talk" => 13,
    "Category" => 14,"Category_talk" => 15,
    "Portal" => 100,"Portal_talk" => 101,
    "Book" => 108, "Book_talk" => 109,
  }
=end 
    # grab file name
    def process line
      yield ENV.pretty_inspect
    end
  end
end

Wukong::Script.new(
  PageviewsToTSV::Mapper,
  nil
).run
