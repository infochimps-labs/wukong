#!/usr/bin/env ruby
# encoding:UTF-8

lines = 0
chars = 0
$invalid_chars = 0
$invalid_lines = 0
time = Time.new.to_i

def print_info
  puts "\nLines: #{lines}"
  puts "Invalid lines: #{$invalid_lines}"
  puts "Invalid line percent: #{$invalid_lines/lines.to_f}%"
  puts "Characters: #{chars}"
  puts "Invalid characters: #{$invalid_chars}"
  puts "Invalid char percent: #{$invalid_chars/chars.to_f}%"
  puts "Time: #{(Time.new.to_i - time)/60.0} minutes"
  puts "Lines/Sec: #{lines.to_f/(Time.new.to_i - time.to_f)}"
end

def guard_encoding_if line, &blk
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

def guard_encoding_rescue line, &blk
  blk.call(line)
rescue StandardError => err
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

Signal.trap("INT") do
  print_info
  exit
end

valid_chars = [(' '..'~')].map{|i| i.to_a}.flatten

start_time = Time.new.to_i
end_time = start_time + 3 * 60

while Time.new.to_i <= end_time
  line = (0..100).map{ valid_chars[rand(valid_chars.length)]}.join
  if rand(100) >= 99
    line << "\x80"
  end
  lines+=1
  chars+= 100
  guard_encoding_if(line) {|l| l =~/./}
end

print_info
