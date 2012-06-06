module Wukong
  module Widget

    class Stringifier < Processor
    end

    class ToJson < Stringifier
      def process(record)
        emit MultiJson.dump(record)
      end
      register_processor
    end

    class FromJson < Stringifier
      # FIXME some of this belongs in gorillib factories...
      def process(record)
        obj = MultiJson.load(record)
        if obj.respond_to?(:has_key?) && obj.has_key?("_metadata")
          metadata_hash = obj.delete("_metadata")
          obj.define_singleton_method(:_metadata) do
            metadata_hash
          end
        end
        if obj.respond_to?(:has_key?) && obj.has_key?("_type")
          klass = Gorillib::Factory(obj.delete("_type"))
          obj = klass.receive(obj)
        end
        emit obj
      end
      register_processor
    end

    class ToTsv < Stringifier
      def process(record)
        emit record.join("\t")
      end
      register_processor
    end

    class FromTsv < Stringifier
      def process(record)
        emit record.chomp.split(/\t/)
      end
      register_processor
    end

  end

end
