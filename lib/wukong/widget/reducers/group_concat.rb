require_relative("group")

module Wukong
  class Processor

    # Concatenates the elements of a group, yielding the group key,
    # the count, and its members.
    #
    # @example Concatenating elements of a group on the command-line.
    #
    #   $ cat input
    #   {"id": 1, "parent_id": 4}
    #   {"id": 2, "parent_id": 3}
    #   {"id": 3, "parent_id": 3}
    #   ...
    #   $ cat input | wu-local group_concat --by=parent_id
    #   4	1	{"id": 1, "parent_id": 4}
    #   3	2	{"id": 2, "parent_id": 3}	{"id": 3, "parent_id": 3}
    #   ...
    #
    # GroupConcat takes all the same options as Group.
    #
    # @see Group
    class GroupConcat < Group

      description <<EOF
This processor concatenates records of a consecutive group of records
into a single record.

  $ cat input
  {"id": 1, "parent_id": 4}
  {"id": 2, "parent_id": 3}
  {"id": 3, "parent_id": 3}
  ...

  $ cat input | wu-local group_concat --by=parent_id
  4	1	{"id": 1, "parent_id": 4}
  3	2	{"id": 2, "parent_id": 3}	{"id": 3, "parent_id": 3}
  ...

Each output record consists of tab-separated fields in the following
order:

  1) The key defining the group of input records in this output record
  2) The number of input records in the group
  3) Each input record in the group
  ...

This processor will not produce any output for a given group until it
sees the last record of that group. See the documentation for the
'group' processor for more information.
EOF

      # The members of the current group.
      attr_accessor :members

      # Initializes the empty members array.
      def setup
        super()
        @members = []
      end

      # Initializes the empty members array.
      #
      # @param [Object] record
      def start record
        super(record)
        self.members = []
      end

      # Accumulate each record, adding it to the current members.
      #
      # @param [Object] record
      def accumulate record
        super(record)
        self.members << record
      end
      
      # Yields the group, including its key, its size, and each
      # member.
      #
      # @yield [key, size, *members]
      # @yieldparam [Object] key the key defining the group
      # @yieldparam [Integer] size the number of members in the group
      # @yieldparam [Array<Object>] the members of the group
      def finalize
        group = [key, size]
        group.concat(members)
        yield group.map(&:to_s).join("\t")
      end

      register
    end
  end
end


    
