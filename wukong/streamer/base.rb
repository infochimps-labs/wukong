module Wukong
  module Streamer
    class Base
      #
      # Accepts option hash from script runner
      #
      def initialize options={}
      end

      #
      # itemize and process each line
      #
      def stream
        $stdin.each do |line|
          item = itemize(line) ; next if item.blank?
          process(*item)
        end
      end

      #
      # Default itemizer: process each record as an array of fields by splitting
      # at field separator
      #
      def itemize line
        line.chomp.split("\t")
      end

      #
      # Implement your own [process] method
      #

      #
      # To track processing errors inline,
      # pass the line back to bad_record!
      #
      def bad_record! *args
        warn "Bad record #{args.inspect[0..400]}"
        puts ["bad_record", args].flatten.join("\t")
      end
    end
  end
end
