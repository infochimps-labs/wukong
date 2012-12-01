require_relative("accumulator")
require_relative("../utils")

module Wukong
  class Processor

    # Sorts input records.
    #
    # For many use cases you're better off using native tools like
    # `/bin/sort` because they are faster and already do what you
    # need.
    #
    # @example When /bin/sort is more than enough on the command-line
    #
    #   $ cat input
    #   1	apple
    #   2	banana
    #   3	cat
    #   4	banana
    #   ...
    #   $ cat input | sort -k2
    #   1	apple
    #   2	banana
    #   4	banana
    #   3	cat
    #   ...
    #
    # Other times, you need something that can introspect more on its
    # input:
    #
    # @example When you may prefer the sort widget on the command-line
    #
    #   $ cat input
    #   {"id": 1, "word": "apple" }
    #   {"id": 2, "word": "cat"   }
    #   {"id": 3, "word": "banana"}
    #   ...
    #   $ cat input | wu-local sort --on word
    #   {"id": 1, "word": "apple" }
    #   {"id": 3, "word": "banana"}    
    #   {"id": 2, "word": "cat"   }
    #   ...
    #
    # The sort widget is useful for modeling Hadoop jobs, but don't
    # forget that [Hadoop does its own
    # sorting](http://hadoop.apache.org/docs/r0.20.2/mapred_tutorial.html#Sort),
    # so the sort widget doesn't belong in your map/reduce jobs.
    #
    # @example The wrong way to model a Hadoop map/reduce job
    #
    #   Wukong.dataflow(:my_incorrect_job_dataflow) do
    #     parse | extract(part: 'country') | sort | group
    #   end
    #
    # @example The right way to model a Hadoop map/reduce job
    #
    #   Wukong.dataflow(:mapper) do
    #     parse | extract(part: 'country')
    #   end
    #   
    #   Wukong.dataflow(:reducer) do
    #     group
    #   end
    class Sort < Accumulator
      
      include DynamicGet
      field :on,        Whatever
      field :reverse,   :boolean, :default => false
      field :numeric,   :boolean, :default => false

      # Intializes the array of records that will hold all the values.
      def setup
        super()
        @records = []
      end

      # Keeps all the records in a single group so they can be sorted.
      #
      # @param [Object] record
      # @return [:__first__group__]
      def get_key(record)
        :__first_group__
      end

      # Stores the `record` for later sorting.
      #
      # @param [Object] record
      def accumulate record
        @records << record
      end
      
      # Sorts all the stored records and yields in one sorted
      # according to the field in the right order.
      #
      # @yield [record] each record in correct sort order
      # @yeildparam [Object] record
      def finalize
        sorted = @records.sort{ |x, y| compare(x, y) }
        sorted.reverse! if reverse
        sorted.each{ |record| yield record }
      end

      # Extracts the sortable part of the input `record`.
      #
      # @param [Object] record
      # @return [Object] the part of the record to sort on
      def sortable(record)
        get(self.on, record)
      end

      # Compare records `x` and `y` using their sortable parts.
      #
      # Will use numeric sorting when asked.
      #
      # @param [Object] x
      # @param [Object] y
      # @return [1,0,-1] depends on which of x or y is considered greater
      def compare(x, y)
        a = (sortable(x) or return -1) 
        b = (sortable(y) or return  1)
        if numeric
          a = a.to_f ; b = b.to_f
        end
        a <=> b
      end

      register
    end
  end
end
