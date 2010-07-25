module Monkeyshines
  module Store
    class Base
      attr_accessor :options
      def initialize _options={}
        self.options = _options
        Log.info "Creating #{self.class}"
      end

      #
      def each_as klass, &block
        self.each do |*args|
          begin
            item = klass.new *args[1..-1]
          rescue Exception => e
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
