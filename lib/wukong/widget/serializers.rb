module Wukong
  module Widget

    class Serializer < Processor
    end

    class ToJson < Serializer
      def process(record)
        yield ::MultiJson.dump(record)
      end
      register
    end

    class FromJson < Serializer
      def process(record)
        yield ::MultiJson.load(record)
      end
      register
    end

    class ToTsv < Serializer
      def process(record)
        yield record.join("\t")
      end
      register
    end

    class FromTsv < Serializer
      def process(record)
        yield record.split(/\t/)
      end
      register
    end

    class ToInspectStr < Serializer
      def process(*args)
        yield args.inspect
      end
    end
    
    class Pretty < Processor
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
