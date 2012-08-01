#!/usr/bin/env ruby
# encoding:UTF-8

def guard_encoding line, &blk
  if line.valid_encoding?
    blk.call(line)
  else 
    $invalid_lines +=1
    repaired_line = []
    line.each_char do |char|
      if char.valid_encoding?
        repaired_line << char
      else
        $invalid_chars +=1
        repaired_line << "�"
      end
    end
    blk.call(repaired_line.join)
  end
end

ARGF.each_line do |line|
  guard_encoding(line) { |line| $stdout.write line }
end
