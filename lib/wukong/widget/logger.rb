module Wukong
  class Processor

    # A widget that will log all incoming records.
    #
    # @example Logging records from the command line
    #
    #   $ cat input
    #   1
    #   2
    #   3
    #   $ cat input | wu-local logger
    #   2012-11-28 18:20:46 [INFO] Logger: 1
    #   2012-11-28 18:20:46 [INFO] Logger: 2
    #   2012-11-28 18:20:46 [INFO] Logger: 3
    #
    # @example Logging records within a dataflow
    #
    #   Wukong.dataflow(:uses_logger) do
    #     ... | logger
    #   end
    class Logger < Processor
      field :level, Symbol, :default => :info, :doc => "Log level priority"

      description <<EOF
This processor passes all input records unmodified, making a log
statement on each one.

  $ cat input
  1
  2
  3
  $ cat input | wu-local logger
  INFO 2013-01-04 17:10:59 [Logger              ] -- 1
  INFO 2013-01-04 17:10:59 [Logger              ] -- 2
  INFO 2013-01-04 17:10:59 [Logger              ] -- 3

You can set the priority level of the log messages with the --level
flag.

  $ cat input | wu-local logger --level=debug
  DEBUG 2013-01-04 17:10:59 [Logger              ] -- 1
  DEBUG 2013-01-04 17:10:59 [Logger              ] -- 2
  DEBUG 2013-01-04 17:10:59 [Logger              ] -- 3
EOF

      # Process a given `record` by logging it.
      #
      # @param [Object] record
      def process(record)
        log.send(level, record)
      end
      register
    end
  end
end
