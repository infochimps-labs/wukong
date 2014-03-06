module Wukong
  class Processor

    # Yield the result of this processor's action for each input
    # record.
    #
    # @example Apply a function (like a parser) to each record
    #
    #   Wukong.dataflow(:parser) do
    #     ... |  map { |string| MyParser.parse(string) } | ...
    #   end
    #
    # @example Succintly map between objects
    #
    #   Wukong.dataflow(:converter) do
    #     ... | my_book_parser | map(&:author) | author_processor | ...
    #   end
    #
    # Can also be called with the :compact option which will check if
    # the result of the action is non falsy before yielding.
    #
    # @example Mapping but only if it exists
    #
    #   Wukong.dataflow(:converter_and_trimmer) do
    #     ... | my_book_parser | map(compact: true, &:author) | processor_that_needs_an_author | ...
    #   end
    class Map < Processor

      field :compact, :boolean, default: false

      # Call #perform_action on the input_record and yield the
      # returned output record.
      #
      # If #compact then only yield the output record if it is not
      # falsy.
      #
      # @param [Object] input_record
      # @yield [output_record] if compact, then only yield if it is not falsy
      # @yieldparam [Object] output_record the result of #perform_action
      #
      # @see Flatten
      def process(input_record)
        output_record = perform_action(input_record)
        if compact
          yield output_record if output_record
        else
          yield output_record
        end
      end
      register
    end

    # If an input record defines the #each method then yield each of
    # its records.  Otherwise yield the input record.
    #
    # @example Turning one record into many
    #
    #   Wukong.dataflow(:authors_to_books) do
    #     ... | author_parser | map(&:books) | flatten | book_processor | ...
    #   end
    #
    # @see Map
    class Flatten < Processor

      # If input_record responds to #each then yield each of these as
      # an output record.  Else, just yield the input_record.
      #
      # @param [Object] input_record
      # @yield [output_record]
      # @yieldparam [Object] output_record
      def process(input_record)
        if input_record.respond_to?(:each)
          input_record.each{ |output_record| yield(output_record) }
        else
          yield(input_record)
        end
      end
      register
    end

  end
end
