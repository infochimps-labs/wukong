require_relative('utils')

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

    # A widget that extracts parts of incoming records.
    #
    # This widget can extract part of the following kinds of objects:
    #
    #   - Hash
    #   - Array
    #   - JSON string
    #   - delimited string ("\t" or "," or other)
    #   - models
    #
    # In each case it will attempt to appropriately parse its
    # <tt>:part</tt> argument.
    #
    # @example Extracting a column from an input TSV record on the command-line
    #
    #   $ cat input
    #   snap	crackle	pop
    #   1	2	3
    #   $ cat input | wu-local extract --part=2
    #   crackle
    #   pop
    #
    # @example Extracting a column from delimited data with a different delimiter
    #
    #   $ cat input
    #   snap,crackle,pop
    #   1,2,3
    #   $ cat input | wu-local extract --part=2 --delimiter=,
    #   crackle
    #   pop
    #
    # @example Extracting a field from within some JSON record on the command-line
    #
    #   $ cat input
    #   {"id": 1, "text": "hi there"}
    #   {"id": 2, "text": "goodbye"}
    #   $ cat input | wu-local extract --part="text"
    #   hi there
    #   goodbye
    #
    # This even works on nested keys using a dot ('.') to separate the
    # keys:
    # 
    # @example Extracting a nested field from within some JSON record on the command-line
    #
    #   $ cat input
    #   {"id": 1, {"data": {"text": "hi there"}}
    #   {"id": 2, {"data": {"text": "goodbye"}}
    #   $ cat input | wu-local extract --part="data.text"
    #   hi there
    #   goodbye
    #
    # Objects like Hashes, Arrays, and models, which would have to
    # serialize within a command-line flow, can also be extracted from
    # within a dataflow:
    #
    # @example Extracting a field from within a Hash in a dataflow
    #
    #   Wukong.dataflow(:uses_extract) do
    #     ... | extract(part: 'data.text') | ...
    #   end
    #
    # @see DynamicGet
    class Extract < Processor
      include DynamicGet

      description <<EOF
This processor will pass extracted parts of input records.

It can be used to extract a field from a delimited input

  $ cat input
  snap	crackle	pop
  a	b	c
  $ cat input | wu-local extract --part=2
  crackle
  b

The default separator is a tab character but you can specify this as
well

  $ cat input
  snap,crackle,pop
  a,b,c
  $ cat input | wu-local extract --part=2 --separator=,
  crackle
  b

It can also be used on JSON records, even those with nested fields

  $ cat input
  {"id": 1, {"data": {"text": "hi there"}}
  {"id": 2, {"data": {"text": "goodbye"}}
  $ cat input | wu-local extract --part=id
  1
  2
  $ cat input | wu-local extract --part=data.text
  hi there
  goodbye

If no --part argument is given, the original record will be yielded.
EOF

      field :part, Whatever, :default => nil, :doc => "Part of the record to extract"

      # Extract a `part` of a `record`.
      #
      # @param [Object] record
      # @yield [part]
      # @yieldparam [Object] part the part extracted from the record
      def process record
        yield get(self.part, record)
      end
      register
    end
    
    # Until further notice, this processor is unusable due to the invocation of yield
    # class Foreach < Processor
    #   def process(record, &blk)
    #     perform_action(record, &blk)
    #   end
    #   register
    # end

    class Map < Processor
      def process(record)
        yield perform_action(record)
      end
      register
    end
    
    class Flatten < Processor
      def process(records)
        records.respond_to?(:each) ? records.each{ |record| yield(record) } : yield(records)
      end
      register
    end

    # Mixin processor behavior
    module BufferedProcessor
      def setup()                           ; end
      def process(record) @buffer << record ; end
      def stop()                            ; end
    end
  
    module StdoutProcessor
      def setup()         $stdout.sync        ; end
      def process(record) $stdout.puts record ; end
      def stop()                              ; end
    end
  end
end
