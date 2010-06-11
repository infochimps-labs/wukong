require 'cassandra' ; include Cassandra::Constants
module Wukong
  module Streamer

    class CassandraStreamer < Wukong::Streamer::Base
      attr_accessor :batch_count, :batch_record_count, :column_space, :batch_size, :db_seeds

      def cassandra_db
        @cassandra_db ||= Cassandra.new(self.column_space, self.db_seeds)
      end

      def initialize *args
        super *args
        self.batch_count = 0
        self.batch_record_count = 0
        self.column_space ||= 'Twitter'
        self.batch_size = 100
        self.db_seeds = %w[10.244.191.178 10.243.19.223 10.243.17.219 10.245.70.85 10.244.206.241].map{ |s| s.to_s+':9160'}
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
        Raise "Overwrite this method to insert into cassandra db"
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
        self.batch_record_count < self.batch_size
      end

    end
  end

end

