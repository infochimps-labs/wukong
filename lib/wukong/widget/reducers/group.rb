require_relative("../utils")
require_relative("count")

module Wukong
  class Processor

    # Groups sorted input records and emits each group with a count.
    #
    # Allows you to use several ways of extracting the key that
    # defines the group.
    #
    # **Note:** The input records must be previously sorted by the
    # same key used for grouping in order to ensure that groups are
    # not split up.
    #
    # @example Group simple string values on the command-line.
    #
    #   $ cat input
    #   apple
    #   cat
    #   banana
    #   apple
    #   ...
    #   $ cat input | wu-local sort | wu-local group
    #   apple	4
    #   banana	2
    #   cat	5
    #   ...
    #
    # @example Group using a nested key within a JSON string on the command-line
    #
    #   $ cat input
    #   {"id": 1, "word": "apple" }
    #   {"id": 2, "word": "cat"   }
    #   {"id": 3, "word": "banana"}
    #   ...
    #   $ cat input | wu-local sort --on=word | wu-local group --by=word
    #   apple	4
    #   banana	2
    #   cat	5
    #   ...
    #
    # A group fits nicely at the end of a dataflow.  Since it requires
    # a sort, it is blocking.
    #
    # @example Using a group at the end of a dataflow
    #
    #   Wukong.dataflow(:makes_groups) do
    #     ... | sort(on: 'field') | group(by: 'field')
    #   end
    #
    # @see Sort
    class Group < Count

      description <<EOF
This processor groups consecutive input records that share the same
"group key".  There are several ways to extract this group key from a
record.

NOTE: The input records must be previously sorted by the
same key used for grouping in order to ensure that groups are
not split up.

By default the input records themselves are used as their own group
keys, allowing to count identical values, a la `uniq -c`:

  $ cat input
  apple
  cat
  banana
  apple
  ...

  $ cat input | wu-local sort | wu-local group
  apple	4
  banana	2
  cat	5
  ...

You can also group by some part of in input record:

  $ cat input
  {"id": 1, "word": "apple" }
  {"id": 2, "word": "cat"   }
  {"id": 3, "word": "banana"}
  ...

  $ cat input | wu-local sort --on==word | wu-local group --by=word
  apple	4
  banana	2
  cat	5
  ...

This processor will not produce any output for a given group until it
sees the last record of that group.
EOF

      include DynamicGet
      field :by, Whatever, :doc => "Part of the record to group by"

      # Get the key which defines the group for this `record`.
      #
      # @param [Object] record
      # @return [Object]
      def get_key(record)
        get(self.by, record)
      end

      # Reset the size counter for new group.
      #
      # @param [Object] record
      def start record
        self.size = 0
      end
      
      # Yields the current group along with its size
      #
      # @yield [key, size]
      # @yieldparam [Object] key the key defining the group
      # @yieldparam [Integer] size the size of the group
      def finalize
        yield [key, size]
      end

      register
    end
  end
end
