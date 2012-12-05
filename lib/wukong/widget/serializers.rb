module Wukong
  module Widget

    SerializerError = Class.new(StandardError)

    class Serializer < Processor
      field :on_error, Symbol, default: :log

      def handle_error(record, err)
        case on_error
        when :log    then log.warn "Bad record: #{record}. Error: #{err.backtrace.join("\n")}"
        when :notify then notify('error', record: record, error: err)
        end          
      end

    end

    class ToJson < Serializer
      field :pretty, :boolean, default: false
      
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

    class FromJson < Serializer
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

    class ToTsv < Serializer
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

    class FromTsv < Serializer
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

    class ToInspectStr < Serializer
      def process(record)
        yield record.inspect
      end
      register(:inspect)
    end
    
    class Recordize < Serializer
      field :model, Whatever

      def process(record)
        wire_format = record.try(:to_wire) || record
        raise SerializerError.new("Record must be in hash format to be recordized") unless wire_format.is_a?(Hash)
        yield model.receive(wire_format)
      rescue => e        
        handle_error(record, e)  
      end
      register
    end    
  end
end
