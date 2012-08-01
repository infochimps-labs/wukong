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

    def guard_encoding line, &blk
      blk.call(line)
    rescue StandardError => err
      $invalid_lines +=1
      repaired_line = []
      line.each_char do |char|
        if char.valid_encoding?
          repaired_line << char
        else
          $invalid_chars +=1
          repaired_line << "?"
        end
      end
      blk.call(repaired_line.join)
    end

    def process line
      guard_encoding(line) do |safe_line|
        @@line_num+=1
        match_num=0
        return unless safe_line =~ /INSERT INTO/
        safe_line.scan(RECORD_RE).each do |fields|
          match_num+=1
          STRING_FIELDS.each do |index|
            orig = fields[index].dup
            fields[index] = fields[index][1..-2]
            fields[index].gsub!(/\\(['"\\])/,'\1')
          end
          safe_line = fields.join("\t")
          yield fields
        end
      end
    end
  end
end

# go to town
Wukong::Script.new(
  ToTSV::Mapper,
  nil
).run
