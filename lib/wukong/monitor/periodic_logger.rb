module Monkeyshines
  module Monitor

    #
    # Emits a log line but only every +iter_interval+ calls or +time_interval+
    # lapse.
    #
    # Since the contents of the block aren't called until the criteria are met,
    # you can put relatively expensive operations in the log without killing
    # your iteration time.
    #
    class PeriodicLogger < PeriodicMonitor
      #
      # Call with a block that returns a string or array to log.
      # If you return
      #
      # Ex: log if it has been at least 5 minutes since last announcement:
      #
      #   periodic_logger = Monkeyshines::Monitor::PeriodicLogger.new(:time => 300)
      #   loop do
      #     # ... stuff ...
      #     periodic_logger.periodically{ [morbenfactor, crunkosity, exuberance] }
      #   end
      #
      def periodically &block
        super do
          now = Time.now.utc.to_f
          result = [ "%10d"%iter, "%7.1f"%since, "%7.1f"%inst_rate(now), (block ? block.call : nil) ].flatten.compact
          Log.info result.join("\t")
        end
      end
    end
  end
end
