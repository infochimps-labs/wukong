require 'wukong/parser/sql_parser'

module Wukong
  module Streamer
    class SQLStreamer < Wukong::Streamer::Base
     
      def self.columns columns
        @@sql_parser = Wukong::Parser::SQLParser.new columns
      end

      def stream
        Log.info("Streaming on:\t%s" % [Script.input_file]) unless Script.input_file.blank?
        before_stream
        each_record do |line|
          recordize(line.chomp) do |record|
            next if record.nil?
            process(*record) do |output_record|
              emit output_record
            end
            track(record)
          end
        end
        after_stream
      end

      def recordize line, &blk
        @@sql_parser.parse line, &blk
      end
    end
  end
end
