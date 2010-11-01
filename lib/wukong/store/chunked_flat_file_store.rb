require 'wukong/monitor/periodic_monitor'
module Wukong
  module Store
    class ChunkedFlatFileStore < Wukong::Store::FlatFileStore
      attr_accessor :filename_pattern, :chunk_monitor, :handle, :chunktime, :rootdir

      # Move to configliere
      Settings.define :chunk_file_pattern,   :default => ":rootdir/:date/:handle-:timestamp-:pid.tsv",:description => "The pattern for chunked files."
      Settings.define :chunk_file_interval,  :default => 4*60*60,  :description => "The time interval to keep a chunk file open."
      Settings.define :chunk_file_rootdir,   :default => '/tmp',   :description => "The root directory for the chunked files."

      #Note that filemode is inherited from flat_file

      def initialize options={}
        # super wants a :filename in the options or it will fail. We need to get the initial filename
        # set up before we call super, so we need all of the parts of the pattern set up.
        self.chunktime        = options[:interval] || Settings[:chunk_file_interval]
        self.rootdir          = options[:rootdir]  || Settings[:chunk_file_rootdir]
        self.handle           = options[:handle]
        pattern               = options[:pattern]  || Settings[:chunk_file_pattern]
        self.filename_pattern = FilenamePattern.new(pattern, :handle => handle, :rootdir => self.rootdir)
        options[:filename]    = filename_pattern.make()
        options[:filemode]  ||= 'a'
        Log.warn "You don't really want a chunk time this small: #{self.chunktime}" unless self.chunktime > 600
        self.chunk_monitor    = Wukong::Monitor::PeriodicMonitor.new( :time => self.chunktime )

        super options
        self.mkdir!
      end

      def new_chunk!
        new_filename = filename_pattern.make()
        Log.info "Rotating chunked file #{filename} into #{new_filename}"
        self.flush
        self.close
        @filename = new_filename
        self.mkdir!
      end

      def save *args
        result = super *args
        chunk_monitor.periodically{ new_chunk! }
        result
      end

    end
  end
end
