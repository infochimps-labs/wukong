module Wukong
  class Processor

    # An empty parent class for all Serializers to subclass.
    class Serializer < Processor
    end

    # A widget for serializing inputs to JSON.
    #
    # @example Serializing to JSON at the end of a data flow
    #
    #   Wukong.dataflow(:emits_json) do
    #     ... | to_json
    #   end
    #
    # @see FromJson
    class ToJson < Serializer
      # Yields the input `record` serialized as JSON.
      #
      # @param [Object] record
      # @yield [json] the serialized json output
      # @yieldparam [String] json
      def process(record)
        begin
          json = ::MultiJson.dump(record)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield json
      end
      register
    end

    # A widget for deserializing inputs from JSON.
    #
    # @example Deserializing from JSON at the beginning of a data flow
    #
    #   Wukong.dataflow(:consumes_json) do
    #     from_json | ...
    #   end
    #
    # @see ToJson
    class FromJson < Serializer
      # Yields the input `record` deserialized from JSON.
      #
      # @param [String] json
      # @yield [obj] the deserialized object
      # @yieldparam [Object] obj
      def process(json)
        begin
          obj = ::MultiJson.load(json)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield obj
      end
      register
    end

    # A widget for serializing inputs to TSV.
    #
    # @example Serializing to TSV at the end of a data flow
    #
    #   Wukong.dataflow(:emits_tsv) do
    #     ... | to_tsv
    #   end
    #
    # @see FromTsv
    class ToTsv < Serializer
      # Yields the input `record` serialized as TSV.
      #
      # @param [Object] record
      # @yield [tsv] the serialized TSV output
      # @yieldparam [String] tsv
      def process(record)
        begin
          tsv = record.map(&:to_s).join("\t")
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield tsv
      end
      register
    end

    # A widget for deserializing inputs from TSV.
    #
    # @example Deserializing from TSV at the beginning of a data flow
    #
    #   Wukong.dataflow(:consumes_tsv) do
    #     from_tsv | ...
    #   end
    #
    # @see ToTsv
    class FromTsv < Serializer
      # Yields the input `record` deserialized from TSV.
      #
      # @param [String] tsv
      # @yield [obj] the deserialized object
      # @yieldparam [Object] obj
      def process(tsv)
        begin
          record = tsv.split(/\t/)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield record
      end
      register
    end

    # A widget for serializing inputs to CSV.
    #
    # @example Serializing to CSV at the end of a data flow
    #
    #   Wukong.dataflow(:emits_csv) do
    #     ... | to_csv
    #   end
    #
    # @see FromCsv
    class ToCsv < Serializer
      # Yields the input `record` serialized as CSV.
      #
      # @param [Object] record
      # @yield [csv] the serialized CSV output
      # @yieldparam [String] csv
      def process(record)
        begin
          csv = record.map(&:to_s).join(",")
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield csv
      end
      register
    end

    # A widget for deserializing inputs from CSV.
    #
    # @example Deserializing from CSV at the beginning of a data flow
    #
    #   Wukong.dataflow(:consumes_csv) do
    #     from_csv | ...
    #   end
    #
    # @see ToCsv
    class FromCsv < Serializer
      # Yields the input `record` deserialized from CSV.
      #
      # @param [String] csv
      # @yield [obj] the deserialized object
      # @yieldparam [Object] obj
      def process(csv)
        begin
          record = csv.split(/,/)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield record
      end
      register
    end

    # A widget for serializing inputs to a delimited format.
    #
    # @example Serializing to a delimited format at the end of a data flow
    #
    #   Wukong.dataflow(:emits_delimited) do
    #     ... | to_delimited(delimiter: "--")
    #   end
    #
    # @see FromDelimited
    class ToDelimited < Serializer
      field :delimiter, String, :default => "\t"
      # Yields the input `record` serialized in a delimited format..
      #
      # @param [Object] record
      # @yield [delimited] the serialized delimited output
      # @yieldparam [String] delimited
      def process(record)
        begin
          delimited = record.map(&:to_s).join(delimiter)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield delimited
      end
      register
    end

    # A widget for deserializing inputs from a delimited format.
    #
    # @example Deserializing from a delimited format at the beginning of a data flow
    #
    #   Wukong.dataflow(:consumes_delimited) do
    #     from_delimited(delimiter: "--") | ...
    #   end
    #
    # @see ToDelimited
    class FromDelimited < Serializer
      field :delimiter, String, :default => "\t"
      # Yields the input `record` deserialized from a delimited format.
      #
      # @param [String] delimited
      # @yield [obj] the deserialized object
      # @yieldparam [Object] obj
      def process(delimited)
        begin
          record = delimited.split(delimiter)
        rescue => e
          # FIXME -- should we log here or what?
          return
        end
        yield record
      end
      register
    end

    # A widget for serializing inputs to Ruby's `inspect` format.
    #
    # @example Serializing to Ruby's inspect format at the end of a data flow
    #
    #   Wukong.dataflow(:emits_inspected) do
    #     ... | to_inspect
    #   end
    class ToInspect < Serializer
      # Yields the input record(s) passed through Ruby's `inspect`.
      #
      # @param [Array<Object>]
      # @yield [inspected]
      # @yieldparam [String] inspected
      def process(*args)
        yield args.size == 1 ? args.first.inspect : args.inspect
      end
      register
    end

    # A widget for pretty printing input records.
    #
    # @example Pretty printing JSON on the command-line
    #
    #   $ cat input
    #   {"id": 1, "word": "apple" }
    #   $ cat input | wu-local pretty
    #   {
    #     "id":2,
    #     "parent_id":3
    #   }
    class Pretty < Serializer
      # Pretty print `record` if we can.
      #
      # @param [Object] record
      # @yield [pretty]
      # @yieldparam [String] pretty the pretty-printed record
      def process record
        if record.is_a?(String) && record =~ /^\s*\{/
          yield pretty_json(record)
        else
          yield record.to_s
        end
      end

      # Attempt to pretty-print the given `json`, returning the
      # original on an error.
      #
      # @param [String] json ugly JSON
      # @return [String] prettier JSON
      def pretty_json json
        begin
          MultiJson.dump(MultiJson.load(json), :pretty => true)
        rescue => e
          json
        end
      end
      
      register
    end

  end
end
