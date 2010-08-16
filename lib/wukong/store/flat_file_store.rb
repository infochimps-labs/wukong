require 'fileutils'; include FileUtils

module Wukong
  module Store
    #
    class FlatFileStore < Store::Base
      attr_accessor :filename, :filemode

      #
      # +filename_root+  : first part of name for files
      #
      def initialize options={}
        super options
        self.filename = options[:filename] or raise "Missing filename in #{self.class}"
        self.filemode = options[:filemode] || 'r'
        skip!(options[:skip]) if options[:skip]
      end

      #
      #
      #
      def each &block
        file.each do |line|
          attrs = line.chomp.split("\t")
          next if attrs.blank?
          yield *attrs
        end
      end

      #
      # Read ahead n_lines lines in the file
      #
      def skip! n_lines
        Log.info "Skipping #{n_lines} in #{self.class}:#{filename}"
        n_lines.times do
          file.readline
        end
      end

      #
      # Open the timestamped file,
      # ensuring its directory exists
      #
      def file
        return @file if @file
        Log.info "Opening file #{filename} with mode #{filemode}"
        @file = File.open(filename, filemode)
      end

      # Close the dump file
      def close
        @file.close if @file
        @file = nil
      end

      def flush
        @file.flush if @file
      end

      # Ensure the file's directory exists
      def mkdir!
        dir = File.dirname(filename)
        return if File.directory?(dir)
        Log.info "Making directory #{dir}"
        FileUtils.mkdir_p dir
      end

      # write to the file
      def save obj
        file.puts obj
        obj
      end
      
      # returns the size of the current file
      def size
        return 0 if !@file
        File.size(filename)
      end

      # delegates to +#save+ -- writes the object to the file. Returns self for chaining on the stream.
      def <<(obj)
        save obj
	self
      end

    end
  end
end

