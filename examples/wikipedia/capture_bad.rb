#!/usr/bin/env ruby
Encoding.default_external="utf-8"

require 'wukong'
module ToTSV
  class Mapper < Wukong::Streamer::LineStreamer
    num_fields = 3
    #num_fields = 11
    FIELD_RE = %q{(\\d+|\\d+\\.\\d+|'(?:[^\\\\']|\\\\+.)*')}
    RECORD_RE = /\(#{(FIELD_RE+',') * (num_fields-1)}#{FIELD_RE}\)/
    STRING_FIELDS = [2]
    #STRING_FIELDS = [2,3,8]

    @@line_num = 0

    def process line
      @@line_num+=1
      match_num=0
      begin
        return unless line =~ /INSERT INTO/
        line.scan(RECORD_RE).each do |fields|
          match_num+=1
          STRING_FIELDS.each do |index|
            orig = fields[index].dup
            fields[index] = fields[index][1..-2]
            fields[index].gsub!(/\\(['"\\])/,'\1')
          end
        end
      rescue StandardError => ex
        $stderr.puts "EXCEPTION ON LINE NUM:#{@@line_num} MATCH NUM:#{match_num}"
        $stderr.puts ex.message
        $stderr.puts ex.backtrace
        yield line
      end
    end
  end
end

# go to town
Wukong::Script.new(
  ToTSV::Mapper,
  nil
).run
