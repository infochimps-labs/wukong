module Wukong
  module Formatter

    class Base < Wukong::Streamer::Base
      def Base.inherited(subklass)
        Wukong::Stage.send(:register, :formatter, subklass)
      end
      unregister!(:streamer)
    end

    require 'multi_json'
    class ToJson < Wukong::Formatter::Base
      def call(record)
        emit MultiJson.encode(record)
      end
    end

    class FromJson < Wukong::Formatter::Base
      def call(record)
        emit MultiJson.decode(record)
      end
    end
    
    class ToTsv < Wukong::Formatter::Base
      def call(record)
        emit record.join("\t")
      end
    end

    class FromTsv < Wukong::Formatter::Base
      def call(record)
        emit record.chomp.split(/\t/)
      end
    end
    
  end
  
end
