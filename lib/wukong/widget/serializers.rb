module Wukong
  module Widget

    class Serializer < Processor
      field :on_error, Symbol, default: :log

      def handle_error(record, err)
        case on_error
        when :log    then log.warn "Bad record: #{record}. Error: #{err.backtrace[0..10].join("\n")}"
        when :notify then notify('error', record: record, error: err)
        end          
      end

    end

    SerializerError = Class.new(StandardError)

    class ToJson < Serializer
      field :pretty, :boolean, default: false
      
      def process(record)
        raise SerializerError.new("Cannot serialize: <nil>") if record.nil?
        if record.respond_to?(:as_json)
          json = record.as_json(pretty: pretty)
        else
          json = ::MultiJson.dump(record.try(:to_wire) || record, pretty: pretty)
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
          obj = ::MultiJson.load(record)
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
          tsv = (record.try(:to_wire) || record.map(&:to_s)).join("\t")
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
      register(:to_inspect)
    end
    
    class Recordizer < Serializer
      field :model, Class
      def process(record)
        yield model.receive(record.try(:to_wire) || record)
      rescue => e
        handle_error(record, e)  
      end
    end
    
    class Pretty < Serializer
      def process record
        case record
        when /^\s*\{/
          yield pretty_json(record)
        else
          yield record
        end
      end

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
