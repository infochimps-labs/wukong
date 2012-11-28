require_relative("../utils")
require_relative("count")

module Wukong
  class Processor
    class Group < Count

      include DynamicGet
      field :by, Whatever

      def get_key(record)
        get(self.by, record)
      end

      def finalize
        yield({ :group => key, :count => size })
      end

      def start record
        self.size = 0
      end
      
      register
    end
  end
end
