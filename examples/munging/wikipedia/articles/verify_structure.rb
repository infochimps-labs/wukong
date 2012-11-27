
# cat /mnt/data/origin/dumps.wikimedia.org/enwiki/20120601/enwiki-20120601-pages-articles.xml  | ruby -ne '$_.chomp!; case $_ when %r{\A(\s*)<redirect title="[^"]+" />\z} then puts %Q{#{$1}<redirect title=\"...\" />} when %r{\A(\s*<[^>]+>)[^<]*(</\w+>)\z} then puts "#{$1}...#{$2}" ; when %r{\A(\s*<[^>]+>)} then puts $1 ; when %r{\A[^<]*(</[\w-]+>)\z} then puts $1 else false end ' > /mnt/data/origin/dumps.wikimedia.org/enwiki/20120601/xml-tags-seen.txt &

# cat /mnt/data/origin/dumps.wikimedia.org/enwiki/20120601/xml-tags-seen.txt | sort -S1G --temp=/mnt{,2,3,4}/tmp | uniq -c  | sort -n | tee xml-tags-census.txt

# cat /mnt/data/origin/dumps.wikimedia.org/enwiki/20120601/xml-tags-seen.txt | sort -S1800M --temp=/mnt{2,3,4}/tmp | uniq -c  | sort -n | tee xml-tags-census.txt &


# 609844   <page>
# 609844     <title>...</title>
# 609844     <ns>...</ns>
# 609844     <id>...</id>
#    714     <restrictions>...</restrictions>
#
# 251254     <redirect title="..." />
# 609844     <revision>
# 609844       <id>...</id>
# 609844       <timestamp>...</timestamp>
#
# 609843       <contributor>
# 548236         <username>...</username>
#  61607         <ip>...</ip>
# 548236         <id>...</id>
# 609843       </contributor>
#
# 288319       <minor />
# 529222       <comment>...</comment>
#    108       <comment>
#    108 </comment>
#
# 224818       <text xml:space="preserve">...</text>
# 385019       <text xml:space="preserve">
#      7       <text xml:space="preserve" />
#
# 346490       <sha1>...</sha1>
# 263354       <sha1 />
#
# 609843     </revision>
# 609843   </page>
#
# 384998 </text>
#     20  </text>
#  643676 </page>
