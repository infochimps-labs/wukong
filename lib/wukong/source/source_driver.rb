module Wukong
  module Source

    # A driver which works just like the `Wukong::Local::StdioDriver`
    # except it ignores input from `STDIN` and instead generates its
    # own input records according to some periodic schedule.  Each
    # consecutive record produced will be an incrementing positive
    # integer (as a string), starting with '1'.
    class SourceDriver < Wukong::Local::StdioDriver
      
      include Logging

      # The index of the record.
      attr_accessor :index

      # The number of records after which a `Processor#finalize` will
      # be called.
      attr_accessor :batch_size

      # Sets the initial value of `index` to 1 and sets the batch size
      # (only if it's positive).
      def post_init
        super()
        self.index = 1
        self.batch_size = settings[:batch_size].to_i if settings[:batch_size] && settings[:batch_size].to_i > 0
      end

      # Starts periodically feeding the processor or dataflow given by
      # `label` using the given `settings`.
      #
      # @param [String, Symbol] label
      # @param [Configliere::Param, Hash] settings
      def self.start(label, settings={})
        driver = new(:foobar, label, settings) # i don't think the 1st argument matters here...
        driver.post_init

        period = case
        when settings[:period]  then settings[:period]
        when settings[:per_sec] then (1.0 / settings[:per_sec]) rescue 1.0
        else 1.0
        end
        driver.create_event
        EventMachine::PeriodicTimer.new(period) { driver.create_event }
      end

      # Creates a new event using the following steps:
      #
      # 1. Feeds a record with the existing `index` to the dataflow.
      # 2. Increments the `index`.
      # 3. Finalizes the dataflow if the number of records is a
      #    multiple of the `batch_size`.
      #
      # @see DriverMethods
      def create_event
        receive_line(index.to_s)
        self.index += 1
        finalize_dataflow if self.batch_size && (self.index % self.batch_size) == 0
      end

      # Outputs a `record` from the dataflow or processor to `STDOUT`.
      #
      # `STDOUT` will automatically be flushed to force output to
      # prevent the feeling of "no output" when the looping period is
      # long.
      #
      # @param [Object] record the record yielded by the processor or the terminal node(s) of the dataflow
      def process record
        $stdout.puts record
        $stdout.flush
      end
      
    end
  end
end
