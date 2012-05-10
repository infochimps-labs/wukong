module Wukong
  class Stringifier < Wukong::Transform

    # def Stringifier.inherited(subklass)
    #   Wukong.register_formatter(subklass)
    # end

    require 'multi_json'
    class ToJson < Wukong::Stringifier
      def call(record)
        emit MultiJson.encode(record)
      end
    end

    class FromJson < Wukong::Stringifier
      def call(record)
        emit MultiJson.decode(record)
      end
    end

    class ToTsv < Wukong::Stringifier
      def call(record)
        emit record.join("\t")
      end
    end

    class FromTsv < Wukong::Stringifier
      def call(record)
        emit record.chomp.split(/\t/)
      end
    end

  end

end
