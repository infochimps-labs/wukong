module Monkeyshines
  module Monitor
    #
    # Accepts a lightweight call every iteration.
    #
    # Once either a time or an iteration criterion is met, executes the block
    # and resets the timer until next execution.
    #
    # Note that the +time_interval+ is measured *excution to execution* and not
    # in multiples of iter_interval. Say I set a time_interval of 300s, and
    # happen to iterate at 297s and 310s after start.  Then the monitor will
    # execute at 310s, and the next execution will happen on or after 610s.
    #
    # Also note that when *either* criterion is met, *both* criteria are
    # reset. Say I set a time interval of 300s and an +iter_interval+ of 10_000;
    # and that at 250s I reach iteration 10_000.  Then the monitor will execute
    # on or after 20_000 iteration or 550s, whichever happens first.
    #
    class PeriodicMonitor
      attr_accessor :time_interval, :iter_interval
      attr_accessor :last_time, :current_iter, :iter, :started_at

      def initialize options={}
        self.started_at    = Time.now.utc.to_f
        self.last_time     = started_at
        self.iter          = 0
        self.current_iter  = 0
        self.time_interval = options[:time]
        self.iter_interval = options[:iters]
      end

      # True if more than +iter_interval+ has elapsed since last execution.
      def enough_iterations?
        iter % iter_interval == 0 if iter_interval
      end

      # True if more than +time_interval+ has elapsed since last execution.
      def enough_time? now
        (now - last_time) > time_interval if time_interval
      end

      # Time since monitor was created
      def since
        Time.now.utc.to_f - started_at
      end
      # Overall iterations per second
      def rate
        iter.to_f / since.to_f
      end
      # "Instantaneous" iterations per second
      def inst_rate now
        current_iter.to_f / (now-last_time).to_f
      end

      #
      # if the interval conditions are met, executes block; otherwise just does
      # bookkeeping and returns.
      #
      def periodically &block
        self.iter += 1
        self.current_iter += 1
        now       = Time.now.utc.to_f
        if enough_iterations? || enough_time?(now)
          block.call(iter, (now-last_time))
          self.last_time = now
          self.current_iter = 0
        end
      end
    end

  end
end
