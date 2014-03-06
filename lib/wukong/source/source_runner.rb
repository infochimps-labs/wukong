require_relative('source_driver')
module Wukong
  module Source

    # Implements the `wu-source` command.
    class SourceRunner < Wukong::Local::LocalRunner

      usage "PROCESSOR|DATAFLOW"

      description <<-EOF.gsub(/^ {8}/,'')
        wu-source is a tool for using Wukong processors as sources of
        data in streams.

        Run any Wukong processor as a source for data:

          $ wu-source fake_log_data
          205.4.75.208 - 3918471017 [27/Nov/2012:05:06:57 -0600] "GET /products/eget HTTP/1.0" 200 25600
          63.181.105.15 - 3650805763 [27/Nov/2012:05:06:57 -0600] "GET /products/lacinia-nulla-vitae HTTP/1.0" 200 3790
          227.190.78.101 - 39543891 [27/Nov/2012:05:06:58 -0600] "GET /products/odio-nulla-nulla-ipsum HTTP/1.0" 200 31718
          ...

        The fake_log_data processor will receive an event once every
        second.  Each event will consist of a single string giving a
        consecutive integer starting with '1' as the first event.
      EOF
      
      include Logging

      # The driver class used by `wu-source`.
      #
      # @return [Class]
      def driver
        SourceDriver
      end

    end
  end
end
