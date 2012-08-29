# encoding:UTF-8

module Wukong
  module Streamer
    module EncodingCleaner
      
      # Replaces all malformed characters in the 
      # input stream with a "?".
      def each_record &block
        $stdin.each do |line|
          if line.valid_encoding?
            block.call(line)
          else 
            repaired_line = []
            line.each_char do |char|
              if char.valid_encoding?
                repaired_line << char
              else
                repaired_line << "?"
              end
            end
            block.call(repaired_line.join)
          end
        end
      end

    end
  end
end
