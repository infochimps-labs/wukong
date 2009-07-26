#!/usr/bin/env ruby
$: << ENV['WUKONG_PATH'] if ENV['WUKONG_PATH']
require 'wukong'

#
# This is so very very kludgey
#
# Input is an 'ls' file, listing files to .bz2 package.
#
# Reducer takes each in turn and creates, within a parallel directory tree under
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
  PKGD_DIR = 'pkgd'

  #
  #
  class Reducer < Wukong::Streamer::Base
    def announce str
      return if str.blank?
      $stderr.puts str
      $stdout.puts str
    end

    def remove_target_filename output_filename
      begin announce "rm\t#{"%-70s"%output_filename}\t" +
          `( hadoop dfs -rmr #{output_filename} ) 2>&1`
      rescue ; nil ; end
    end

    def mkdir_target_safely output_filename
      output_dir = File.dirname(output_filename)
      begin announce "mkdir\t#{"%-70s"%output_dir}\t" +
          `( hadoop dfs -mkdir #{output_dir} ) 2>&1`
      rescue ; nil ; end
    end

    def bzip_into_pkgd_file input_filename, output_filename
      announce "cat|bz\t#{"%-70s"%input_filename}\t" +
        `( hadoop dfs -cat #{input_filename}/[^_]\\* | bzip2 -c | hadoop dfs -put - #{output_filename} ) 2>&1`
    end

    def verify input_filename, output_filename
      announce "sha1sum\t#{"%-70s"%output_filename}\t" +
        `( hadoop dfs -cat #{output_filename}        | bzcat - | sha1sum ) 2>&1`
      announce "sha1sum\t#{"%-70s"%input_filename}\t" +
        `( hadoop dfs -cat #{input_filename}/[^_]\\*           | sha1sum ) 2>&1`
    end

    def gen_output_filename input_filename
      "%s/%s.bz2" % [PKGD_DIR, input_filename.gsub(%r{^/},"")]
    end

    def process input_filename, output_filename
      # remove_target_filename output_filename
      # mkdir_target_safely    output_filename
      bzip_into_pkgd_file    input_filename, output_filename
      verify                 input_filename, output_filename
    end

    def stream
      announce `hostname`
      $stdin.each do |input_filename|
        # handle ls or straight file list, either
        input_filename = input_filename.chomp.strip.split(/\s/).last
        output_filename = gen_output_filename input_filename
        announce "********************************************************"
        announce "Packing\t#{"%-70s"%input_filename}\t#{output_filename}"
        process input_filename, output_filename
        announce "Done\t#{"%-70s"%input_filename}\t#{output_filename}\n\n"
      end
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :timeout => (24 * 60 * 60 * 1000)  # milliseconds in one day
    end
  end
end

#
# Execute the script
#
ExportPackager::Script.new(nil, ExportPackager::Reducer, :reduce_tasks => 1000).run
