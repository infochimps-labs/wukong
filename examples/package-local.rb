#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../lib'

require 'wukong'

#
# This is so very very kludgey
#
# Input is an 'ls' file, listing files to .bz2 package.
#
# Mapper takes each in turn and creates, within a parallel directory tree under
# ~/pkgd on the HDFS, a .bz2 compressed version of the file.
#
# So, the file
#   /user/me/fixd/all-20090103
# is packaged onto the DFS as
#   /user/me/pkgd/user/me/fixd/all-20090103
#
#   listing=tmp/fixd-all-package-listing
#   hdp-rm $listing
#   hadoop dfs -lsr fixd | egrep '(part-|\.tsv$)' | hdp-put - $listing ;
#
#   ./package.rb --run --rm --map_tasks=1 $listing $pkgd_log
#
module ExportPackager
  PKGD_DIR = '/workspace/flip/pkgd'

  #
  #
  class Reducer < Wukong::Streamer::Base
    def announce *args
      $stdout.puts *args
      $stderr.puts *args
    end

    def handle_existing_target output_filename
      return true unless File.exist?(output_filename)
      #   announce "Exists! #{output_filename}"
      #   return false
      announce "Removing target file #{output_filename}"
      begin announce `rm #{output_filename}`
      rescue Exception => e ; announce e ; end
      true
    end

    def mkdir_target_safely output_filename
      output_dir = File.dirname(output_filename)
      announce "Ensuring directory #{output_dir} exists"
      begin announce `mkdir -p #{output_dir}`
      rescue Exception => e ; announce e ; end
    end

    def bzip_into_pkgd_file input_filename, output_filename
      announce "bzip'ing into #{output_filename}"
      announce `( hadoop dfs -cat #{input_filename}/[^_]\** ) | bzip2 -c > #{output_filename}`
    end

    def gen_output_filename input_filename
      input_filename += '.tsv' unless input_filename =~ /.*\.\w{2,}/
      "%s/%s.bz2" % [PKGD_DIR, input_filename.gsub(/^\//, '')]
    end

    def rsync host, local_path, remote_path=nil
      remote_path ||= local_path
      announce `/usr/bin/rsync -Cuvrtlp #{local_path} #{host}:#{remote_path}`
      sleep 5
    end

    def process input_filename
      output_filename = gen_output_filename(input_filename)
      handle_existing_target(output_filename) or return
      mkdir_target_safely    output_filename
      bzip_into_pkgd_file    input_filename, output_filename
      rsync :lab3, output_filename
      #
    end

    def recordize line
      # handle ls or straight file list, either
      line.split(/\s/).last
    end

    def stream
      super
      rsync :lab3, PKGD_DIR+'/'
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :map_tasks => 1,
        :max_node_reduce_tasks => 1, # only one reducer per local filesystem
        :timeout => 40 * 60 * 1000   # timeout in ms
    end
  end
  # Execute the script
  Script.new(nil, Reducer).run
end


