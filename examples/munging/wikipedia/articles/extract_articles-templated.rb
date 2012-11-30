#!/usr/bin/env ruby

# Extracts wikipedia articles from bzipped xml, outputs them in TSV.  Article
# text is XML encoded, but all newlines and tabs (in fact, all control
# characters) are converted to XML entities, making it safe to truck around as
# TSV.

# ## Schema
#
# Sample Pig LOAD Statement:
#
# all_articles = LOAD '$articles' AS
#   (id:long, namespace:int, title:chararray, revision_timestamp:long, redirect:chararray, text:chararray);
#

# ## Usage
#
# Flattens the wikipedia 'enwiki-latest-pages-articles.xml.gz' into a
# one-line-per-record heap.
#
#    examples/munging/wikipedia/articles/extract_articles-templated.rb --rm --run \
#      /data/origin/dumps.wikimedia.org/enwiki/20120601/enwiki-20120601-pages-articles.xml
#      /data/results/wikipedia/full/articles.json.tsv
#

require 'wukong'
require 'wukong/streamer/encoding_cleaner'
require 'crack/xml'
require 'multi_json'
require_relative '../utils/munging_utils.rb'

# <page>
#   <title>Anarchism</title>
#   <ns>0</ns>
#   <id>12</id>
#   <revision>
#     <id>370845941</id>
#     <timestamp>2010-06-29T20:14:56Z</timestamp>
#     <contributor>
#       <username>Centographer</username>
#       <id>12640258</id>
#     </contributor>
#     <minor />
#     <comment>clarifying not ordinary anarcho-socialism</comment>
#     <text xml:space="preserve">
#       ...snip ...
#     </text>
#     <sha1>...</sha1>
#   </revision>
# </page>
#
module ArticlesExtractor
  class Mapper < Wukong::Streamer::LineStreamer
    include Wukong::Streamer::EncodingCleaner
    include MungingUtils

    def initialize(*)
      super
      @lines      = []
      @state        = :out_of_article
      @num_lines    = 0
    end

    # Bolt together all lines between a <page> and a </page> marker.
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

    def process article
      info = ARTICLE_RE.match(article)
      if not info then warn "Bad match line #{@lines}: #{article.to_s[0..2000]}" ; return ; end

      timestamp = [info[:rts_yr], info[:rts_mo], info[:rts_day], info[:rts_hr], info[:rts_min], info[:rts_sec], 'Z'].join
      text      = Crack::XML::parse("<text>#{info[:text]}</text>")['text'] || ''
      redirect  = info[:redirect] || ''

      record = [
        info[:id],
        info[:ns],
        scrub_control_chars(info[:title]),
        info[:revision_id],
        timestamp,
        scrub_control_chars(redirect),
        safe_json_encode(text)
      ]
      yield record
    end
  end

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

end

# Force it to run in a single map task, to avoid writing a custom input format.
# The job runs in 2 hours, once; much less than the time it'd take me to do so.
Wukong::Script.new(ArticlesExtractor::Mapper, nil, min_split_size: 1152921504606846976).run
