require_relative('utils')

module Wukong
  class Processor

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
  end
end
