module Monkeyshines
  module Store
    class ChunkedFlatFileStore < Monkeyshines::Store::FlatFileStore
      attr_accessor :filename_pattern, :chunk_monitor, :handle

      DEFAULT_OPTIONS = {
        :chunktime    => 4*60*60, # default 4 hours
        :pattern   => ":rootdir/:date/:handle+:timestamp-:pid.tsv",
        :rootdir   => nil,
        :filemode  => 'w',
      }

      def initialize _options
        self.options = DEFAULT_OPTIONS.deep_merge(_options)
        raise "You don't really want a chunk time this small: #{options[:chunktime]}" unless options[:chunktime] > 600
        self.chunk_monitor    = Monkeyshines::Monitor::PeriodicMonitor.new( :time => options[:chunktime] )
        self.handle           = options[:handle] || Monkeyshines::CONFIG[:handle]
        self.filename_pattern = Monkeyshines::Utils::FilenamePattern.new(options[:pattern], :handle => handle, :rootdir => options[:rootdir])
        super options.merge(:filename => filename_pattern.make())
        self.mkdir!
      end

      def save *args
        result = super *args
        chunk_monitor.periodically do
          new_filename = filename_pattern.make()
          Log.info "Rotating chunked file #{filename} into #{new_filename}"
          self.close
          @filename = new_filename
          self.mkdir!
        end
        result
      end

    end
  end
end
