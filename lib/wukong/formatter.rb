module Wukong
  class Formatter < Wukong::Streamer

    def Formatter.inherited(subklass)
      Wukong.register_formatter(subklass)
    end

    require 'multi_json'
    class ToJson < Wukong::Formatter
      def call(record)
        emit MultiJson.encode(record)
      end
    end

    class FromJson < Wukong::Formatter
      def call(record)
        emit MultiJson.decode(record)
      end
    end

    class ToTsv < Wukong::Formatter
      def call(record)
        emit record.join("\t")
      end
    end

    class FromTsv < Wukong::Formatter
      def call(record)
        emit record.chomp.split(/\t/)
      end
    end

  end

end
