#!/usr/bin/env ruby

dir_to_rename = ARGV[0]
dest_ext = '.tsv'

unless dir_to_rename && (! dir_to_rename.empty?)
  warn "Need a directory or file spec to rename."
  exit
end

#
# Setup
#
warn "\nPlease IGNORE the 'cat: Unable to write to output stream.' errors\n"

#
# Examine the files
#
file_listings = `hdp-ls #{dir_to_rename}`.split("\n")
command_lists = { }
file_listings[1..-1].each do |file_listing|
  m = %r{[-drwx]+\s+[\-\d]+\s+\w+\s+\w+\s+(\d+)\s+[\d\-]+\s+[\d\:]+\s+(.+)$}.match(file_listing)
  if !m then warn "Couldn't grok #{file_listing}" ; next ; end
  size, filename = m.captures
  case
  when size.to_i == 0 then (command_lists[:deletes]||=[]) << filename
  else
    firstline = `hdp-cat #{filename} | head -qn1 `
    file_key, _ = firstline.split("\t", 2)
    unless file_key && (file_key =~ /\A[\w\-\.]+\z/)
      warn "Don't want to rename to '#{file_key}'... skipping"
      next
    end
    dirname = File.dirname(filename)
    destfile = File.join(dirname, file_key)+dest_ext
    (command_lists[:moves]||=[]) << "hdp-mv #{filename} #{destfile}"
  end
end

#
# Execute the command_lists
#
command_lists.each do |type, command_list|
  case type
  when :deletes
    command = "hdp-rm #{command_list.join(" ")}"
    puts command
    `#{command}`
  when :moves
    command_list.each do |command|
      puts command
      `#{command}`
    end
  end
end


# -rw-r--r--   3 flip supergroup          0 2008-12-20 05:51 /user/flip/out/sorted-tweets-20081220/part-00010

# # Killing empty files
# find . -size 0 -print -exec rm {} \;
#
# for foo in part-0* ; do
#   newname=`
#     head -n1 $foo |
#     cut -d'   ' -f1 |
#     ruby -ne 'puts $_.chomp.gsub(/[^\-\w]/){|s| s.bytes.map{|c| "%%%02X" % c }}'
#     `.tsv ;
#   echo "moving $foo to $newname"
#   mv "$foo" "$newname"
# done
#
# # dir=`basename $PWD`
# # for foo in *.tsv ; do
# #   echo "Compressing $dir"
# #   bzip2 -c $foo > ../$dir-bz2/$foo.bz2
# # done
