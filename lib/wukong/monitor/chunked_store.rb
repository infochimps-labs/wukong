require 'monkeyshines/monitor/periodic_monitor'
module Monkeyshines
  module Monitor
    module ChunkedStore
      attr_accessor :file_pattern
      def initialize file_pattern
        self.file_pattern = file_pattern
        super file_pattern.make
      end

      def close_and_reopen
        close
        self.filename = file_pattern.make
        dump_file
      end

      def save *args
        chunk_monitor.periodically{ close_rename_and_open }
        super *args
      end
    end
  end
end
