require 'fileutils'; include FileUtils

module Monkeyshines
  module Store
    #
    class FlatFileStore < Store::Base
      attr_accessor :filename, :filemode

      #
      # +filename_root+  : first part of name for files
      #
      def initialize options={}
        Log.debug "New #{self.class} as #{options.inspect}"
        self.filename = options[:filename] or raise "Missing filename in #{self.class}"
        self.filemode = options[:filemode] || 'r'
        skip!(options[:skip]) if options[:skip]
      end

      #
      #
      #
      def each &block
        file.each do |line|
          next if line[0..0] == '#'
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

      # Ensure the file's directory exists
      def mkdir!
        dir = File.dirname(filename)
        return if File.directory?(dir)
        Log.info "Making directory #{dir}"
        FileUtils.mkdir_p dir
      end

      # write to the file
      def save obj
        file << obj.to_flat.join("\t")+"\n"
        obj
      end
      
      # returns the size of the current file
      def size
        return 0 if !@file
        File.size(filename)
      end

      def set key, *args, &block
        tok, obj = block.call
        save obj
      end

      # delegates to +#save+ -- writes the object to the file
      def <<(obj)
        save obj
      end

    end
  end
end

