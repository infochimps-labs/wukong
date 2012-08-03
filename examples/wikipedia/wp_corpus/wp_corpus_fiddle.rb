#!/usr/bin/env ruby

require 'wukong'
require 'crack/xml'
load '/home/dlaw/dev/wukong/examples/wikipedia/munging_utils.rb'

module XMLTest
  class Mapper < Wukong::Streamer::LineStreamer

    def lines
      @lines ||= []
    end
    
    def get_keys hash
      if hash.is_a?(Hash)
        result = {}
        hash.keys.each do |key|
          result[key] = get_keys(hash[key])
        end  
        return result
      end  
      return nil
    end

    def recordize line
      MungingUtils.guard_encoding(line) do |safe_line|
        lines << safe_line
        if safe_line =~ /<\/page>/
          result = Crack::XML::parse(lines.join)
          @lines = []
          puts "Page schema: #{get_keys(result)}"
          return [result]
        else
          return nil
        end
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
