require 'time' # ain't it always that way
module Wukong
  module Dfs
    def self.list_files dfs_path
      Log.info{ "DFS: listing #{dfs_path}" }
      listing = `hadoop dfs -ls #{dfs_path}`.split("\n").reject{|ls_line| ls_line =~ /Found \d+ items/i}
      listing.map{|ls_line| HFile.new_from_ls(ls_line)}
    end

    #
    # FIXME -- this will fail if multiple files in a listing have the
    # same basename. Sorry.
    #
    def self.compare_listings src_files, dest_files, &block
      src_files.sort.each do |src_file|
        dest_file = dest_files.find{|df| File.basename(src_file) == df.basename }
        case
        when (! dest_file)                       then yield :missing, src_file, nil
        when (! dest_file.kinda_equal(src_file)) then yield :differ,  src_file, dest_file
        else                                          yield :same,    src_file, dest_file
        end
      end
    end

    HFile = TypedStruct.new(
      [:mode_str,     String],
      [:i_count,      String],
      [:owner,        String],
      [:group,        String],
      [:size,         Integer],
      [:date,         Bignum],
      [:path,     String]
      )
    HFile.class_eval do
      def self.new_from_ls ls_line
        mode, ic, o, g, sz, dt, tm, path = ls_line.chomp.split(/\s+/)
        date = Time.parse("#{dt} #{tm}").utc.to_flat
        new mode, ic.to_i, o, g, sz.to_i, date, path
      end
      def dirname
        @dirname ||= File.dirname(path)
      end
      def basename
        @basename ||= File.basename(path)
      end
      #
      # Two files are kinda_equal if they match in size and if
      # the hdfs version is later than the filesystem version.
      #
      def kinda_equal file
        (self.size == File.size(file)) # && (self.date >= File.mtime(file).utc.to_flat)
      end
      def to_s
        to_a.join("\t")
      end

      #
      # These will be very slow.
      # If some kind soul will integrate JRuby callouts the bards shall
      # celebrate your name evermore.
      #

      # rename the file on the HDFS
      def mv new_filename
        self.class.run_dfs_command :mv, path, new_filename
      end

      def self.mkdir dirname
        run_dfs_command :mkdir, dirname
      end
      def self.mkdir_p(*args) self.mkdir *args ; end # HDFS is always -p

      def self.run_dfs_command *args
        cmd = 'hadoop dfs -'+ args.flatten.compact.join(" ")
        Log.debug{ "DFS: Running #{cmd}" }
        Log.info{ `#{cmd} 2>&1`.gsub(/[\r\n\t]+/, " ") }
      end

    end
  end
end
