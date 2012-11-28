require_relative("group")

module Wukong
  class Processor
    class GroupConcat < Group
      attr_accessor :members
      
      def setup
        super()
        @members = []
      end

      def start record
        super(record)
        self.members = []
      end

      def finalize
        yield({:group => key, :count => size, :members => members})
      end

      def accumulate record
        super(record)
        self.members << record
      end
      register
    end
  end
end


    
