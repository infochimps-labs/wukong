require 'zlib'
require 'forkjoin'
require 'archive/tar/minitar'

# from http://www.igvita.com/2012/02/29/work-stealing-and-recursive-partitioning-with-fork-join/

pool = ForkJoin::Pool.new

jobs = Dir[ARGV[0].chomp('/') + '/*'].map do |dir|
  Proc.new do
    puts "Threads: #{pool.active_thread_count}, #{Thread.current} processing: #{dir}"

    backup = "/tmp/backup/#{File.basename(dir)}.tgz"
    tgz = Zlib::GzipWriter.new(File.open(backup, 'wb'))
    Archive::Tar::Minitar.pack(dir, tgz)

    File.size(backup)
  end
end

results = pool.invoke_all(jobs).map(&:get)
puts "Created #{results.size} backup archives, total bytes: #{results.reduce(:+)}"

# $> ruby backup.rb /home/igrigorik/
