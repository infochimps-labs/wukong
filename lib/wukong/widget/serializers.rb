module Wukong
  class Processor

    SerializerError = Class.new(Error)

    class Serializer < Processor
      field :on_error, String, default: 'log', :doc => "Action to take upon an error, either 'log' or 'notify'"

      def handle_error(record, err)
        return if err.class == Errno::EPIPE
        case on_error
        when 'log'    then log.warn "#{err.class}: #{err.message}"
        when 'notify' then notify('error', record: record, error: err)
        end          
      end

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

      description <<EOF
Turns input records into JSON strings.

Pretty print input with the --pretty flag.
EOF
      
      field :pretty, :boolean, default: false, :doc => "Pretty-print output"

      # Yields the input `record` serialized as JSON.
      #
      # @param [Object] record
      # @yield [json] the serialized json output
      # @yieldparam [String] json
      def process(record)
        raise SerializerError.new("Cannot serialize: <nil>") if record.nil?
        if record.respond_to?(:to_json) && !record.is_a?(Hash) # We only want to invoke to_json if it has been explicitly defined
          json = record.to_json(pretty: pretty)
        else
          json = MultiJson.dump(record.try(:to_wire) || record, pretty: pretty)
        end
        yield json
      rescue => e
        handle_error(record, e)
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

      description <<EOF
Parse JSON input records into native Ruby objects.

  $ cat input.json
  {"hi": "there"}
  $ cat input.json | wu-local from_json
  {"hi"=>"there"}
EOF
      
      # Yields the input `record` deserialized from JSON.
      #
      # @param [String] json
      # @yield [obj] the deserialized object
      # @yieldparam [Object] obj
      def process(record)
        if record.respond_to?(:from_json)
          obj = record.from_json
        else
          obj = MultiJson.load(record)
        end
        yield obj
      rescue => e
        handle_error(record, e)       
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
        if record.respond_to?(:to_tsv)
          tsv = record.to_tsv
        else         
          wire_format = record.try(:to_wire) || record
          raise SerializerError.new("Record must be in Array format to be serialized as TSV") unless wire_format.respond_to?(:map)
          tsv = wire_format.map(&:to_s).join("\t")
        end
        yield tsv
      rescue => e
        handle_error(record, e)
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
      def process(record)
        if record.respond_to?(:from_tsv)
          obj = record.from_tsv
        else
          obj = record.split(/\t/)
        end
        yield obj
      rescue => e        
        handle_error(record, e)
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
      field :delimiter, String, :default => "\t", :doc => "Delimiter to use between fields in a record"
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
      field :delimiter, String, :default => "\t", :doc => "Delimiter to use between fields in a record"
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
      def process(record)
        yield record.inspect
      end
      register
    end

    # A widget for turning a record into an instance of some class.
    # The class must provide a "class method" `receive` which accepts
    # a Hash argument.
    class Recordize < Serializer
      field :model, Whatever, :doc => "Model class to turn records into"

      # Turn the given `record` into an instance of the class named
      # with the `model` field.
      #
      # @param [Hash, #to_wire] record
      # @return [Object]
      def process(record)
        wire_format = record.try(:to_wire) || record
        raise SerializerError.new("Can only recordize a Hash-like record") unless wire_format.is_a?(Hash)
        yield model.receive(wire_format)
      rescue => e
        handle_error(record, e)
      end
      register
    end
  end
end
