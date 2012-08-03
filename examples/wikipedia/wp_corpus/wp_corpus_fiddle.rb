#!/usr/bin/env ruby

require 'wukong'
require 'crack/xml'

module XMLTest
  class Mapper < Wukong::Streamer::LineStreamer

    def lines
      @lines ||= []
    end

    def recordize line
      lines << line
      if line =~ /<\/page>/
        result = Crack::XML::parse(lines.join)
        @lines = []
        return [result]
      else
        return nil
      end
    end

    def char_check (text,title,id)
      text.scan(/([^\x20-\x7E\x0A\x09])/).each do |char|
        puts "Found weird control character on page #{title} id: #{id} - #{char}" 
      end
    end

    def escape text
      text.gsub!(/\n/,"&#10;");
      text.gsub!(/\t/,"&#09;");
    end

    def process record
      char_check(record['page']['revision']['text'],record['page']['title'],record['page']['id'])
      result = []
      result << record['page']['id']
      result << record['page']['title']
      result << record['page']['ns']
      result << record['page']['revision']['timespamp']
      result << escape(record['page']['revision']['text'])
      yield result
    end
  end
end

Wukong::Script.new(XMLTest::Mapper,nil).run
