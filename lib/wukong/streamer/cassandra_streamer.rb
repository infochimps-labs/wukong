require 'cassandra' ; include Cassandra::Constants
module Wukong
  module Streamer

    class CassandraStreamer < Wukong::Streamer::Base
      attr_accessor :batch_count, :batch_record_count, :column_space
      CASSANDRA_DB_SEEDS = %w[10.244.191.178 10.243.19.223 10.243.17.219 10.245.70.85 10.244.206.241].map{ |s| s.to_s+':9160'}
      BATCH_SIZE = 100

      def cassandra_db
        @cassandra_db ||= Cassandra.new(self.column_space, CASSANDRA_DB_SEEDS)
      end

      def initialize *args
        super *args
        self.batch_count = 0
        self.batch_record_count = 0
        self.column_space ||= 'Twitter'
      end

      def stream
        while still_lines? do
          start_batch do
            while still_lines? && batch_not_full? do
              line = get_line
              record = recordize(line.chomp) or next
              next if record.blank?
              process(*record) do |output_record|
                emit output_record
              end
              self.batch_record_count += 1
            end
          end
        end
      end

      def process *args, &blk
        Raise "Overwrite this method, yo"
      end

      def start_batch &blk
        self.batch_record_count = 0
        self.batch_count += 1
        cassandra_db.batch(&blk)
      end

      def get_line
        $stdin.gets
      end

      def still_lines?
        !$stdin.eof?
      end

      def batch_not_full?
        self.batch_record_count < BATCH_SIZE
      end

    end
  end

end

