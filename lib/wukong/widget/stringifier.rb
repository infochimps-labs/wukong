module Wukong
  module Widget

    class Stringifier < Processor
    end

    class ToJson < Stringifier
      register_processor
      def process(record)
        emit ::MultiJson.dump(record)
      end
    end

    class FromJson < Stringifier
      register_processor
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
    end

    class ToTsv < Stringifier
      register_processor
      def process(record)
        emit record.to_tsv
      end
    end

    class FromTsv < Stringifier
      register_processor
      def process(record)
        emit record.split(/\t/)
      end
    end


    class ToInspectStr < Stringifier
      register_processor
      def process(*args)
        emit(args.inspect)
      end
    end

  end

end
