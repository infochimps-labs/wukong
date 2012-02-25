module Wukong
  module Store
    class ChhChunkedFlatFileStore < Wukong::Store::FlatFileStore
      attr_accessor :filename_pattern, :handle, :rootdir

      # Move to configliere
      Settings.define :chunk_file_pattern,   :default => ":rootdir/:date/:handle:timestamp-:pid.tsv",:description => "The pattern for chunked files."
      Settings.define :chunk_file_rootdir,   :default => nil, :description => "The root directory for the chunked files."

      #Note that filemode is inherited from flat_file

      def initialize options={}
        # super wants a :filename in the options or it will fail. We need to get the initial filename
        # set up before we call super, so we need all of the parts of the pattern set up.
        self.rootdir          = options[:rootdir] || Settings[:chunk_file_rootdir]
        self.handle           = options[:handle]
        pattern               = options[:pattern] || Settings[:chunk_file_pattern]
        self.filename_pattern = FilenamePattern.new(pattern, :handle => handle, :rootdir => self.rootdir)
        options[:filename]    = filename_pattern.make()

        super options

        self.mkdir!
      end

      def new_chunk
        new_filename = filename_pattern.make()
        Log.info "Rotating chunked file #{filename} into #{new_filename}"
        self.flush
        self.close
        @filename = new_filename
        self.mkdir!
      end

    end
  end
end
