module Wukong
  module Streamer
    #
    # For each identical line in the map phase output, emit one representative
    # line followed by the count of occrrences (separated by a tab).
    #
    # (This is the functional equivalent of +'uniq -c'+)
    #
    class UniqueCountLinesReducer < Wukong::Streamer::Base
      def freq_key freq
        "%010d"%freq.to_i
      end

      #
      # Delegate to +uniq -c+, but put the count last for idempotence.
      #
      def stream
        %x{/usr/bin/uniq -c}.split("\n").each do |line|
          freq, item = line.chomp.strip.split(/\s+/, 2)
          puts [item, freq_key(freq)].join("\t")
        end
      end
    end

  end
end
