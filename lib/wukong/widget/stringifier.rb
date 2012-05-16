module Wukong
  module Widget

    class Stringifier < Processor
    end


    # def Stringifier.inherited(subklass)
    #   Wukong.register_formatter(subklass)
    # end

    require 'multi_json'
    class ToJson < Stringifier
      def process(record)
        emit MultiJson.encode(record)
      end
      register_processor
    end

    class FromJson < Stringifier
      def process(record)
        emit MultiJson.decode(record)
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
