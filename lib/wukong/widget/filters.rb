module Wukong
  class Processor

    # A widget which filters input records according to some
    # criterion.
    class Filter < Processor

      description <<EOF
A processor which filters input records according to some criterion.
EOF

      # Process a `record` by yielding it only if it should be
      # selected by this filter.
      #
      # @param [Object] record an input record
      # @yield [record] yielded if this record should pass the filter
      # @yieldparam [Object] record
      # @see #select?
      # @see #reject?
      def process(record)
        yield(record) if select?(record)
      end

      # Should the given `record` be passed by this filter?
      #
      # @param [Object] record
      # @return [true, false]
      # @see #reject?
      def select?(record)
        true
      end      

      # Should the given `record` be rejected by this filter?
      #
      # @param [Object] record
      # @return [true, false]
      # @see #select?
      def reject?(record)
        not select?(record)
      end

      register
    end

    # A widget which passes all records, i.e. - it acts just like
    # `cat`.
    #
    # @example Pass all records unmodified on the command line
    #
    #   $ cat input
    #   1
    #   2
    #   3
    #   $ cat input | wu-local identity
    #   1
    #   2
    #   3
    #   
    # @example Pass all records unmodified in a dataflow
    #
    #   Wukong.dataflow(:uses_identity) do
    #     ... | identity | ...
    #   end
    #   
    # @see Filter
    # @see Null
    class Identity < Filter
      description "This processor passes all records unmodified."
      register
    end
    
    # A widget which doesn't pass any records, i.e. - it acts just
    # like <tt>/dev/null</tt>.
    #
    # @example Filter all records on the command line
    #
    #   $ cat input
    #   1
    #   2
    #   3
    #   $ cat input | wu-local null
    #   
    # @example Filter all records from a dataflow
    #
    #   Wukong.dataflow(:uses_null) do
    #     ... | null | ...
    #   end
    #   
    # @see Filter
    # @see All
    class Null < Filter

      description "This processor acts as a filter which passes no records at all."
      
      # Prevents any records from passing because it always returns
      # `false`.
      #
      # @param [Object] record
      # @return false
      def select? record
        false
      end
      register
    end

    # A widget which only passes records if they match a regular
    # expression.
    #
    # @example Passing records which match a given expression on the command-line
    #
    #   $ cat input
    #   apple
    #   banana
    #   cat
    #   $ cat input | wu-local regexp --match='^a'
    #   apple
    #
    # @example Passing records which match a given expression in a dataflow
    #
    #   Wukong.dataflow(:uses_regexp) do
    #     ... | regexp(match: /^a/) | ...
    #   end
    #
    # @see Filter
    # @see NotRegexpFilter
    class RegexpFilter < Filter

      description <<EOF
This processor only passes records which match against a given regular
expression.

  $ cat input
  apple
  banana
  cat
  $ cat input | wu-local regexp --match='^a'
  apple

If no --match argument is given, all records will be passed.
EOF

      field :match, Regexp, :doc => "Regular expression to match against"
      
      # Selects a `record` only if it matches this widget's `match`
      # field.
      #
      # @param [Object] record
      # @return [true, false]
      def select?(record)
        return true unless match
        match =~ record.to_s
      end
      register(:regexp)
    end

    # A widget which only passes records if they *don't* match a
    # regular expression.
    #
    # @example Passing records which don't match a given expression on the command-line
    #
    #   $ cat input
    #   apple
    #   banana
    #   cat
    #   $ cat input | wu-local not_regexp --match='^a'
    #   banana
    #   cat
    #
    # @example Passing records which don't match a given expression in a dataflow
    #
    #   Wukong.dataflow(:uses_not_regexp) do
    #     ... | not_regexp(match: /^a/) | ...
    #   end
    #
    # @see Filter
    # @see NotRegexpFilter
    class NotRegexpFilter < RegexpFilter

      description <<EOF
This processor only passes records which fail to match against a given
regular expression.

  $ cat input
  apple
  banana
  cat
  $ cat input | wu-local not_regexp --match='^a'
  banana
  cat

If no --match argument is given, all records will be passed.
EOF
      
      # Select a `record` only if it <b>doesn't</b> match this
      # widget's `match` field.
      #
      # @param [Object] record
      # @return [true, false]
      def select?(record)
        return true unless match
        not match =~ record.to_s
      end
      register(:not_regexp)      
    end

    # A widget which only lets a certain number of records through.
    #
    # @example Letting the first 3 records through on the command-line
    #
    #   $ cat input
    #   1
    #   2
    #   3
    #   4
    #   $ cat input | wu-local limit --max=3
    #   1
    #   2
    #   3
    #
    # @example Letting the first 3 records through in a dataflow
    #
    #   Wukong.dataflow(:uses_limit) do
    #     ... | limit(max: 3) | ...
    #   end
    #
    # @see Filter
    class Limit < Filter

      description <<EOF
This processor passes a certain number of records and then stops
passing any, acting as a limit.

  $ cat input
  1
  2
  3
  $ cat input | wu-local limit --max=2
  1
  2

If no --max argument is given, all records will be passed.
EOF

      field :max, Integer, :default => Float::INFINITY, :doc => "Maximum number of records to let pass"

      # The current record count.
      attr_accessor :count

      # Initializes the record count to zero.
      def setup
        self.count = 0
      end

      # Select a record only if we're below the max count.  Increments
      # the count for this widget.
      #
      # @param [Object] record
      # @return [true, false]
      def select?(record)
        keep = @count < max
        @count += 1
        keep
      end
      register
    end

    # A widget which samples a certain fraction of input records.
    #
    # @example Sampling records on the command line
    #
    #   $ cat input
    #   1
    #   2
    #   3
    #   4
    #   $ cat input | wu-local sample --fraction=0.5
    #   1
    #   3
    #
    # @example Sampling records in a dataflow
    #
    #   Wukong.dataflow(:uses_sample) do
    #     ... | sample(fraction: 0.5) ...
    #   end
    #
    # @see Filter
    # @see Limit
    class Sample < Filter

      description <<EOF
This processor will pass input records with a certain frequency,
acting as a random sampler.

  $ cat input
  1
  2
  3
  4
  $ cat input | wu-local sample --fraction=0.5
  1
  4

If no --fraction is given, all records will be passed.
EOF

      field :fraction, Float, :default => 1.0, :doc => "Fraction of records to let pass.  Must be between 0 and 1.0"

      # Selects a `record` randomly, with a probability given the the
      # `fraction` for this widget.
      #
      # @param [Object] record
      # @return [true, false]
      def select?(record)
        rand() < fraction
      end
      register
    end

    # A widget useful for creating filters on the fly in a dataflow.
    #
    # When writing a filtering processor out as a class, just use the
    # DSL for creating processors:
    #
    # @example Creating a select filter the usual way
    #
    #   Wukong.processor(:my_filter, Wukong::Processor::Filter) do
    #     def select? record
    #       record.length > 3
    #     end
    #   end
    #
    # When in a dataflow, sometimes it's easier to create a processor
    # like this on the fly.
    #
    # @example Creating a select filter on the fly in a dataflow
    #
    #   Wukong.dataflow(:my_flow) do
    #     ... | select { |record| record.length > 3 } | ...
    #   end
    #
    # @see Filter
    # @see Reject
    class Select < Filter

      # Selects the given `record` by delegating to the
      # `perform_action` method, which will automatically be
      # populating by the block used to create this filter in the
      # dataflow DSL.
      #
      # @param [Object] record
      # @return [true, false]
      # @see Processor#perform_action
      def select?(record)
        perform_action(record)
      end
      register
    end

    # A widget useful for creating filters on the fly in a dataflow.
    #
    # @see Select
    class Reject < Filter
      # Rejects the given `record` by delegating to the
      # `perform_action` method.
      #
      # @param [Object] record
      # @return [true, false]
      # @see Processor#perform_action
      def select?(record)
        not perform_action(record)
      end
      register
    end

    # Emit only the first `n` records.
    #
    # @see Filter
    class Head < Filter

      field :n, Integer, :default => 10, :doc => "Number of records to let pass"

      # The current record count.
      attr_accessor :count

      # Initializes the record count to zero.
      def setup
        self.count = 0
      end

      # Select a record only if we're below the maximum number of
      # records.
      #
      # @param [Object] record
      # @return [true, false]
      def select?(record)
        keep = @count < n
        @count += 1
        keep
      end
      register
    end

    # Skip the first `n` records.
    #
    # Works slightly differently than the UNIX `tail` command which
    # prints the last `n` records.  This notion is less useful in a
    # streaming context, so think of this filter as the equivalent of
    # `tail -n+`.
    #
    # @see Filter
    class Tail < Filter
      
      field :n, Integer, :default => 0, :doc => "Number of records to skip before letting records pass"

      # The current record count
      attr_accessor :count

      # Initializes the record count to zero.
      def setup
        self.count = 0
      end

      # Select a record only if we've already skipped the first `n`
      # records.
      #
      # @param [Object]
      # @return [true, false]
      def select?(record)
        keep = @count >= n
        @count += 1
        keep
      end
      register
    end
    
  end
end
