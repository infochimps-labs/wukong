require_relative("accumulator")

module Wukong
  class Processor

    # A processor which emits only unique records from its input.
    # It's intended to work just like `uniq`.
    #
    # @example Emit unique elements from the input (like `uniq`).
    #
    #   $ uniq input
    #   apple
    #   banana
    #   pear
    #   $ cat input | wu-local uniq
    #   apple
    #   banana
    #   pear
    #
    # @example Emit unique elements from the input with counts (like `uniq -c`).
    #
    #   $ uniq -c input
    #        3 apple
    #        2 banana
    #        3 pear
    #   $ cat input | wu-local uniq --count --to=tsv
    #   apple	3
    #   banana	5
    #   pear	8
    
    class Uniq < Accumulator

      field :count, :boolean, doc: "Emit a count for each group of input records", default: false

      description <<EOF
This processor uniq's its inputs.

    $ uniq input
    apple
    banana
    pear
    $ cat input | wu-local uniq
    apple
    banana
    pear
  
And it can count as well:
  
    $ uniq -c input
         3 apple
         2 banana
         3 pear
    $ cat input | wu-local uniq --count --to=tsv
    apple	3
    banana	5
    pear	8
EOF

      # The total size of the input recors.
      attr_accessor :size

      # Initializes the count to 0.
      def setup
        super()
        @size = 0
      end

      # Accumulate a `record` by incrmenting the total size.
      #
      # @param [Object] record
      def accumulate record
        self.size += 1
      end

      # Yields the total size.
      #
      # @yield [size]
      # @yieldparam [Integer] size
      def finalize
        if count
          yield [key, self.size]
        else
          yield key
        end
      end

      register
    end
  end
end
