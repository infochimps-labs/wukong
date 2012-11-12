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
      register
    end

  end

end
