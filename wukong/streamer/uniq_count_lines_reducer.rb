module Wukong
  module Streamer
    #
    # For each identical line in the map phase output, emit one representative
    # line followed by the count of occrrences (separated by a tab).
    #
    # (This is the functional equivalent of +'uniq -c'+)
    #
    class UniqCountLinesReducer < Wukong::Streamer::Base
      def formatted_key_count key_count
        "%010d"%key_count.to_i
      end

      #
      # Delegate to +uniq -c+, but put the count last for idempotence.
      #
      def stream
        %x{/usr/bin/uniq -c}.split("\n").each do |line|
          key_count, item = line.chomp.strip.split(/\s+/, 2)
          puts [item, formatted_key_count(key_count)].join("\t")
        end
      end
    end

  end
end
