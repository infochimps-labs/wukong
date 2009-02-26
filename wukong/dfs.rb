module Wukong
  module Dfs
    def self.list_files dfs_path
      $stderr.puts "listing #{dfs_path}"
      listing = `hadoop dfs -ls #{dfs_path}`.split("\n").reject{|ls_line| ls_line =~ /Found \d+ items/i}
      listing.map{|ls_line| HFile.new_from_ls(ls_line)}
    end

    def self.compare_listings src_files, dest_files, &block
      src_files.each do |src_file|
        dest_file = dest_files.find{|df| File.basename(src_file) == df.basename }
        case
        when (! dest_file)                       then yield :missing, src_file, nil
        when (! dest_file.kinda_equal(src_file)) then yield :differ,  src_file, dest_file
        else                                          yield :same,    src_file, dest_file
        end
      end
    end

    class HFile < TypedStruct.new(
        [:mode_str,     String],
        [:i_count,      String],
        [:owner,        String],
        [:group,        String],
        [:size,         Integer],
        [:date,         Bignum],
        [:path,     String]
        )
      def self.new_from_ls ls_line
        mode, ic, o, g, sz, dt, tm, path = ls_line.split(/\s+/)
        date = DateTime.parse_and_flatten("#{dt} #{tm}")
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
        (self.size == File.size(file)) &&
        (self.date >= File.mtime(file).strftime("%Y%m%d%H%M00"))
      end
      def to_s
        to_a.join("\t")
      end
    end
  end
end
