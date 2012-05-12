module Wukong
  module Widget

    class Stringifier < Transform
    end
    
    
    # def Stringifier.inherited(subklass)
    #   Wukong.register_formatter(subklass)
    # end

    require 'multi_json'
    class ToJson < Stringifier
      def process(record)
        emit MultiJson.encode(record)
      end
    end

    class FromJson < Stringifier
      def process(record)
        emit MultiJson.decode(record)
      end
    end

    class ToTsv < Stringifier
      def process(record)
        emit record.join("\t")
      end
    end

    class FromTsv < Stringifier
      def process(record)
        emit record.chomp.split(/\t/)
      end
    end

  end

end
