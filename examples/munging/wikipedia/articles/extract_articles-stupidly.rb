#!/usr/bin/env ruby

#  This script extracts wikipedia articles from bzipped xml and outputs
#  them in TSV.
#
#  Sample Pig LOAD Statement:
#  all_articles = LOAD '$articles' AS
#    (id:int, title:chararray, namespace:int, revision_date:int, revision_time:int,
#    revision_epoch_time:long, revision_day_of_week:int, text:chararray);

require 'wukong'
require 'wukong/streamer/encoding_cleaner'
require 'crack/xml'
require File.expand_path('../utils/munging_utils.rb', File.dirname(__FILE__))

MatchData.class_eval do
  def as_hash
    Hash[ names.map{|name| [name.to_sym, self[name]] } ]
  end
end

warn [ENV['LC_ALL'], ENV['LC_NAME'], ENV['LC_CTYPE'], ENV['LANG']]


# Flattens the wikipedia 'enwiki-latest-pages-articles.xml.gz' into a
# one-line-per-record heap.
#
#    examples/munging/wikipedia/articles/extract-articles-stupidly.rb --rm --run \
#      /data/origin/dumps.wikimedia.org/enwiki/20120601/enwiki-20120601-pages-articles.xml
#      /data/results/wikipedia/full/articles.xml.tsv
#
# <page>
#   <title>Anarchism</title>
#   <id>12</id>
#   <revision>
#     <id>370845941</id>
#     <timestamp>2010-06-29T20:14:56Z</timestamp>
#     <contributor>
#       <username>Centographer</username>
#       <id>12640258</id>
#     </contributor>
#     <comment>clarifying not ordinary anarcho-socialism</comment>
#     <text xml:space="preserve">
#       ...snip ...
#     </text>
#   </revision>
# </page>
#
module ArticlesExtractor
  ARTICLE_BEG_RE  = %r{\A\s*<page>\z}
  ARTICLE_END_RE  = %r{\A\s*</page>\z}

  ARTICLE_RE = %r{\A
\s*<page>
\s*  <title>(?<title>[^<]*)</title>
\s*    <ns>(?<ns>\d+)</ns>
\s*    <id>(?<id>\d+)</id>
\s* (?:<redirect\stitle=\"(?<redirect>[^\"]+)\"\s/>)?
\s* (?:<restrictions>(?<restrictions>[^<]+)</restrictions>)?
\s*    <revision>
\s*      <id>(?<revision_id>\d+)</id>
\s*      <timestamp>(?<rts_yr>\d\d\d\d)-(?<rts_mo>\d\d)-(?<rts_day>\d\d)T(?<rts_hr>\d\d):(?<rts_min>\d\d):(?<rts_sec>\d\d)Z</timestamp>
\s* (?:    
          <contributor>\s*<username>[^<]+</username>\s*<id>\d+</id>\s*</contributor> |
          <contributor>\s*<ip>[\d\.]+</ip>\s*</contributor> |
          <contributor\sdeleted="deleted"\s/>
    )
\s*      (?:<minor\s/>)?
\s*      (?:<comment>[^<]*</comment>|<comment\sdeleted="deleted"\s/>)?
\s* (?:
         <text\sxml:space="preserve">
            (?<text>.*)
         </text>
     |
         <text\sxml:space="preserve"\s/>
    )
\s*      (?:<sha1>(?<sha1>[a-z0-9]+)</sha1> | <sha1\s/>)
\s*  </revision>
\s*</page>\s*\z}xmo
  
  class Mapper < Wukong::Streamer::LineStreamer
    include Wukong::Streamer::EncodingCleaner
    include MungingUtils

    def initialize(*)
      super
      @lines      = []
      @state        = :out_of_article
      @num_lines    = 0
    end

    def recordize line
      @num_lines += 1
      return if @state == :out_of_article && (ARTICLE_BEG_RE !~ line)
      @state = :in_article
      #
      @lines << line
      if ARTICLE_END_RE =~ line
        result   = @lines.join("\n")
        @lines   = []
        @state = :out_of_article
        return   [result]
      else
        return nil
      end
    end

    def escape text
      text.gsub!(/[^\x20-\x7e]/){|char| "&##{char.ord};" }
      return text
    end

    def process article
      info = ARTICLE_RE.match(article)
      if not info then warn "Bad match: #{article.to_s[0..2000]}" ; return ; end

      timestamp = [info[:rts_yr], info[:rts_mo], info[:rts_day], info[:rts_hr], info[:rts_min], info[:rts_sec], 'Z'].join
      text      = escape info[:text].to_s

      yield [
        info[:title],       info[:ns], info[:id],   info[:restrictions],
        info[:revision_id], timestamp, info[:sha1], 
        info[:redirect],    text
      ]
    end
    
  end
end

# Force it to run in a single map task, to avoid writing a custom input format.
# The job runs in 2 hours, once; much less than the time it'd take me to do so.
Wukong::Script.new(ArticlesExtractor::Mapper, nil, min_split_size: 1152921504606846976).run
