#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'

require 'wukong'                       ; include Wukong

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

    def remove_target_filename output_filename
      puts "Removing target file #{output_filename}"
      begin puts `hadoop dfs -rmr #{output_filename}`
      rescue ; nil ; end
    end

    def mkdir_target_safely output_filename
      output_dir = File.dirname(output_filename)
      puts "Ensuring directory #{output_dir} exists"
      begin puts `hadoop dfs -mkdir #{output_dir}`
      rescue ; nil ; end
    end

    def bzip_into_pkgd_file input_filename, output_filename
      puts "bzip'ing into #{output_filename}"
      puts `hadoop dfs -cat #{input_filename} | bzip2 -c | hadoop dfs -put - #{output_filename}`
    end

    def gen_output_filename input_filename
      "%s/%s.bz2" % [PKGD_DIR, input_filename]
    end

    def process input_filename, output_filename
      remove_target_filename output_filename
      mkdir_target_safely    output_filename
      bzip_into_pkgd_file    input_filename, output_filename
    end

    def stream
      $stdin.each do |input_filename|
        # handle ls or straight file list, either
        input_filename = input_filename.chomp.split(/\s/).last
        output_filename = gen_output_filename input_filename
        process input_filename, output_filename
      end
    end
  end

  class Script < Wukong::Script
  end
end

#
# Execute the script
#
ExportPackager::Script.new(nil, ExportPackager::Reducer).run
