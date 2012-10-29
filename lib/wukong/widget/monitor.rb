module Wukong
  module Widget

    class Monitor < AsIs
      include CountingProcessor
      register_processor

      magic :every, Integer, :default => 1000, :doc => "How often to announce progress"

      def process(rec)
        super(rec)
        $stderr.puts("%-7d\t%s\t%s" % [count, report, rec.inspect[0..1000]]) if ready?
      end

      def ready?
        (count % every) == 0
      end
    end

    class DumpSystemConfig < Monitor
      def setup ; require 'rbconfig' ;  end
      def report() super.merge({ :rbconfig => RbConfig::CONFIG })  end
    end

  end
end
