#!/usr/bin/env ruby
Encoding.default_external="utf-8"

require 'wukong'
module ToTSV
  class Mapper < Wukong::Streamer::LineStreamer
    # Page links
    num_fields = 3
    STRING_FIELDS = [2]
  
    # Pages
    #num_fields = 11
    #STRING_FIELDS = [2,3,8]

    INTEGER_RE = %q{\\d+}
    FLOAT_RE = %q{\\d+\\.\\d+}
    STRING_RE = %q{'(?:[^\\\\']|\\\\+.)*'}
    FIELD_RE = "(#{INTEGER_RE}|#{FLOAT_RE}|#{STRING_RE})"
    RECORD_RE = /\(#{(FIELD_RE+',') * (num_fields-1)}#{FIELD_RE}\)/

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
          line = fields.join("\t")
          yield fields
        end
      rescue StandardError => ex
        $stderr.puts "*** EXCEPTION on line: #{@@line_num} match num: #{match_num} ***"
        $stderr.puts ex.message
        $stderr.puts ex.backtrace
      end
    end
  end
end

# go to town
Wukong::Script.new(
  ToTSV::Mapper,
  nil
).run
