module Wukong
  module Store
    class Base
      def initialize options={}
        Log.info "Creating #{self.class} with #{options.inspect}"
      end

      #Iterate through each object casting it as a new object of klass.
      def each_as klass, &block
        self.each do |*args|
          begin
            item = klass.new *args[1..-1]
          rescue StandardError => e
            Log.info [args, e.to_s, self].join("\t")
            raise e
          end
          yield item
        end
      end

      def log_line
        nil
      end

    end
  end
end
