module Wukong
  module Widget

    class Serializer < Processor
    end

    class ToJson < Serializer
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

    class FromJson < Serializer
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

    class ToTsv < Serializer
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

    class FromTsv < Serializer
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

    class ToInspectStr < Serializer
      def process(*args)
        yield args.inspect
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
