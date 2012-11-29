#!/usr/bin/env ruby
require_relative './dbpedia_common'
require 'ap'

module Re
  ##
  # Container for the character classes specified in
  # <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>.
  # Borrowed from the addressable gem
  module Uri
    ALPHA      = "a-zA-Z"
    DIGIT      = "0-9"
    GEN_DELIMS = "\\:\\/\\?\\#\\[\\]\\@"
    SUB_DELIMS = "\\!\\$\\&\\'\\(\\)\\*\\+\\,\\;\\="
    RESERVED   = GEN_DELIMS + SUB_DELIMS
    UNRESERVED = ALPHA + DIGIT + "\\-\\.\\_\\~"
    PCHAR      = UNRESERVED + SUB_DELIMS + "\\:\\@"
    SCHEME     = ALPHA + DIGIT + "\\-\\+\\."
    AUTHORITY  = PCHAR
    PATH       = PCHAR + "\\/"
    QUERY      = PCHAR + "\\/\\?"
    FRAGMENT   = PCHAR + "\\/\\?"
    #
    PATHSEG    = ""
  end
end
#
#
#
module Dbpedia

  DBLQ_STRING_C   = '"(?<%s>\\\"|[^\"]+)+"'
  DECIMAL_NUM_RE  = '[\-\+\d]+\.\d+'

  RDF_RES = {
    dbpedia_ontb:     'http://dbpedia\.org/ontology',
    dbpedia_ont:      'http://dbpedia\.org/ontology/(?<%s>[\w\/]+)',
    dbpedia_prop:     'http://dbpedia\.org/property/(?<%s>\w+)',
    dbpedia_class:    'http://dbpedia\.org/class/(?<%s>[^>\s]+)',
    dbpedia_rsrc:     "http://dbpedia\\.org/resource/(?<%s>[#{Re::Uri::PCHAR}%%\/]+)",
    wikipedia_rsrc:   "http://\\w\\w\\.wikipedia\\.org/wiki/(?<%s>[#{Re::Uri::PCHAR}%%\/]+)",
    dbpedia_value:    '"(?<%s>(?:\\\"|[^\"]+)*)"\\^\\^<http://dbpedia\.org/datatype/(?<%s>[a-zA-Z]+)>',
    foaf_homepage:    'http://xmlns\.com/foaf/0\.1/homepage',
    foaf_name:        'http://xmlns\.com/foaf/0\.1/name',
    foaf_topic:       'http://xmlns\.com/foaf/0\.1/(?:isPrimaryTopicOf|primaryTopic)',
    foaf_prop:        'http://xmlns\.com/foaf/0\.1/(?<property>\w+)',
    geonames_rsrc:    'http://sws\.geonames\.org/(?<%s>\d+)/',
    georss_latlng:    '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\\s(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"@en',
    georss_type:      'http://www\.georss\.org/georss/point',
    musicbrainz_rsrc: 'http://zitgist\.com/music/(?<%s>\w+)/(?<%s>[a-f0-9\-]+)',
    nytimes_rsrc:     'http://data\.nytimes\.com/(?<%s>[A-Z0-9]+)',
    purl_subject:     'http://purl\.org/dc/terms/subject',
    purl_desc:        'http://purl\.org/dc/elements/1\.1/(?<%s>description)',
    purl_lang:        'http://purl\.org/dc/elements/1\.1/language',
    rdf_comment:      'http://www\.w3\.org/2000/01/rdf-schema\\#comment',
    rdf_eol:          '\\.',
    rdf_float:        '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"\^\^<http://www\.w3\.org/2001/XMLSchema\#float>',
    rdf_integer:      '\"(?<%s>\d+)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#integer>',
    rdf_date:         '\"(?<%s>\d\d\d\d-\d\d-\d\d)\"\^\^<http://www\.w3\.org/2001/XMLSchema\\#date>',
    rdf_string:       '\"(?<%s>(?:\\\"|[^\"]+)*)"@(?<%s>\w+)\b',
    rdf_label:        'http://www\.w3\.org/2000/01/rdf-schema\\#label',
    rdf_type:         'http://www\.w3\.org/1999/02/22-rdf-syntax-ns\\#type',
    same_as:          'http://www\.w3\.org/2002/07/owl\\#sameAs',
    skos_concept:     'http://www\.w3\.org/2004/02/skos/core\\#(?<%s>[a-zA-Z]+)',
    skos_subject:     'http://www\.w3\.org/2004/02/skos/core\\#subject',
    wgs_latorlng:     'http://www\.w3\.org/2003/01/geo/wgs84_pos\\#(?:lat|long)',
    url_loose:        '(?<%s>(?:https?|ftp)://(?:[a-zA-Z0-9\-]+\.)+(?:[a-zA-Z\-]+)[^\s>]*)',
    wiki_category:    'http://en\.wikipedia\.org/wiki/Category:Futurama?oldid=485425712\\#absolute-line=1',
    wiki_link_id:     'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)\\#?(?:absolute-line=(?<%s>\d+))?',
    wiki_link_id_sec: 'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)\\#?(?:section=(?<%s>.*?)\&relative-line=(?<%s>\d+))?(?:&?absolute-line=(?<%s>\d+))?',
    wordnet_inst:     'http://www\.w3\.org/2006/03/wn/wn20/instances/synset-(?<%s>\w+)-noun-(?<%s>[0-9]+)',
    yago_class:       'http://dbpedia\.org/class/yago',
    rdf_value:        '\"(?<%s>
      -?\d\d\d\d-\d\d-\d\d|-?\d\d\d\d-\d\d|--\d\d-\d\d|
      [\+\-]?\d+  |
      [\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?|
      true|false)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>integer|date|gYearMonth|gMonthDay|gYear|positiveInteger|nonNegativeInteger|float|double|boolean)>',

    schema_type:      'http://(?<%s>www\\.w3\\.org/2002/07/owl|schema\\.org|dbpedia\\.org/ontology|purl\\.org/ontology|xmlns.com/foaf/0\\.1)[/\#]([^>]+)'
  }

  idx = 0;
  RDF_RES.each{|flavor, re_str| Regexp.new(re_str.gsub('%s'){|x| "l#{idx+=1}" }) }

  private
  def self.r(regexp_name, *args)
    RDF_RES[regexp_name] % args
  end
  public

  MAPPINGS = {

    geo_coordinates:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:georss_type)}>                        \s#{r(:georss_latlng, :lat, :lng)}               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    geo_coord_skip_a:      %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<http://www\.opengis\.net/gml/_Feature>        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    geo_coord_skip_b:      %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:wgs_latorlng)}>                       \s#{r(:rdf_float, :val)}                         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    wordnet:               %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_prop, :property)}>            \s<#{r(:wordnet_inst, :wn_class, :wn_idx)}>      \s#{r(:rdf_eol)}  \z}x,
    geonames:              %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:geonames_rsrc, :geonames_id)}>           \s#{r(:rdf_eol)}  \z}x,

    pnd:                   %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/individualisedPnd>     \s#{r(:rdf_string, :name, :nlang)}               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    disambiguations:       %r{\A<#{r(:dbpedia_rsrc, :generic_wikipedia_id)}> \s<#{r(:dbpedia_ontb)}/wikiPageDisambiguates> \s<#{r(:dbpedia_rsrc, :specific_wikipedia_id)}>  \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    page_ids:              %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageID>            \s#{r(:rdf_integer,   :wikipedia_pageid)}        \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}>     \s#{r(:rdf_eol)}  \z}x,
    redirects:             %r{\A<#{r(:dbpedia_rsrc, :dupe_of)}>              \s<#{r(:dbpedia_ontb)}/wikiPageRedirects>     \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>           \s#{r(:rdf_eol)}   \z}x,

    article_categories:    %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:purl_subject)}>                       \s<#{r(:dbpedia_rsrc, :specific_wikipedia_id)}>  \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    categories_skos:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:skos_concept, :skos_relation)}>          \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    categories_skos_label: %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:skos_concept, :skos_relation)}>       \s#{r(:rdf_string, :val, :val_lang)}             \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    categories_skos_reln:  %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:skos_concept, :skos_relation)}>       \s<#{r(:dbpedia_rsrc, :category_b)}>             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    category_labels:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_label)}>                          \s#{r(:rdf_string,:category_wikipedia_id, :ctl)} \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,

    abstracts_short:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_comment)}>                        \s#{r(:rdf_string,:abstract, :al)}               \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    abstracts_long:        %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/abstract>              \s#{r(:rdf_string,:abstract, :al)}               \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}xm,
    titles:                %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_label)}>                          \s#{r(:rdf_string,:wikipedia_id2,  :tl )}        \s<#{r(:wiki_link_id, :wikipedia_id2, :wikipedia_pageid, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    nytimes:               %r{\A<#{r(:nytimes_rsrc, :nyt_id)}>               \s<#{r(:same_as)}>                            \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>           \s#{r(:rdf_eol)}   \z}x,

    external_links:        %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageExternalLink>  \s<#{r(:url_loose, :weblink_url)}>               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    homepages:             %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:foaf_homepage)}>                      \s<#{r(:url_loose, :weblink_url)}>               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    wikipedia_links:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:foaf_topic)}>                         \s<#{r(:url_loose, :weblink_url)}>               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    wikipedia_lang:        %r{\A<#{r(:wikipedia_rsrc, :wikipedia_id)}>       \s<#{r(:purl_lang)}>                          \s#{r(:rdf_string, :lang, :wll_lang)}            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    wikipedia_rev:         %r{\A<#{r(:wikipedia_rsrc, :wikipedia_id)}>       \s<#{r(:foaf_topic)}>                         \s<#{r(:dbpedia_rsrc, :wikipedia_id2)}>          \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    musicbrainz:           %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:musicbrainz_rsrc, :musicbrainz_type, :musicbrainz_id)}>    \s#{r(:rdf_eol)}  \z}x,

    properties_map_val:    %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_value,  :val, :val_type)}             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    properties_map_str:    %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_string, :val, :val_lang)}             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    properties_map_foaf:   %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:foaf_prop, :property)}>               \s#{r(:rdf_string, :val, :val_lang)}             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    properties_specmap:    %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:dbpedia_value, :val, :dbpedia_units)}     \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,

    yago:                  %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:schema_type, :schema, :schema_type)}>    \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,

    persondata_type:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<http://xmlns.com/foaf/0\.1/Person>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    persondata_reln:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s<#{r(:dbpedia_rsrc, :target_wikipedia_id)}>    \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    persondata_prop:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_value, :val, :val_type)}              \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    persondata_foaf:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:foaf_prop, :property)}>               \s#{r(:rdf_string,:name, :name_lang)}            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,
    persondata_desc:       %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:purl_desc, :property)}>               \s#{r(:rdf_string,:name, :name_lang)}            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x,


    #topical_concepts:      %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>       \s<#{r(:skos_subject)}>                       \s<#{r(:x, )} \z}x,  #<http://dbpedia.org/resource/Futurama> \s<#{r(:wiki_category)}> .
    # uscensus:               %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>        \s<#{r(:same_as)}>                            \s<#{r(:url_loose, :census_url)}>   \s#{r(:rdf_eol)}  \z}x,
    # instance_types:        %r{\A<#{r(:dbpedia_rsrc, :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:dbpedia_ont, :specific_wikipedia_id)}> }x,#        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :wikipedia_pageid, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
  }

  # ap MAPPINGS

  class RdfExtractor < Wukong::Streamer::LineStreamer
    include MungingUtils

    def emit(hsh)
      super [MultiJson.encode(hsh)]
    end

    def process(line)
      return if line =~ /\A(?:\#|$)/
      if line =~ /=> \w+\.\w+ <=/ then yield [line] ; return ; end
      MAPPINGS.each do |flavor, re|
        next unless mm = re.match(line)
        yield( { flavor: flavor }.merge(mm.as_hash) )
        return
      end
      puts [line]
    end
  end
end


# META = {
#   geo_coordinates:    [:field,      'geo_coordinates_en.nq',                      ],
#   wordnet:            [:joinkey,    'wordnet_links.nt',                           ],
#   geonames:           [:joinkey,    'geonames_links.nt',                          ],
#   properties_specmap: [:properties, 'specific_mappingbased_properties_en.nq',     ],
#   properties_mapped:  [:properties, 'mappingbased_properties_unredirected_en.nq', ],
#   pnd:                [:joinkey,    'pnd_en.nq',                                  ],
#   disambiguations:    [:pagelink,   'disambiguations_unredirected_en.nq',         ],
#   external_links:     [:weblink,    'external_links_en.nq',                       ],
#   page_ids:           [:field,      'page_ids_en.nq',                             ],
#   redirects:          [:pagelink,   'redirects_transitive_en.nt',                 ],
#   article_categories: [:categories, 'article_categories_en.nq',                   ],
#   instance_types:     [:categories, 'instance_types_en.nq',                       ],
#   categories_skos:    [:meta,       'skos_categories_en.nq',                      ],
#   abstracts_long:     [:field,      'long_abstracts_en.nq',                       ],
#   abstracts_short:    [:field,      'short_abstracts_en.nq',                      ],
#   category_labels:    [:meta,       'category_labels_en.nq',                      ],
#   titles:             [:field,      'labels_en.nq',                               ],
#   musicbrainz:        [:joinkey,    'musicbrainz_links.nt',                       ],
#   nytimes:            [:joinkey,    'nytimes_links.nt',                           ],
#   uscensus:           [:joinkey,    'uscensus_links.nt',                          ],
#   topical_concepts:   [             'topical_concepts_unredirected_en.nq',        ],
#   homepages:          [:weblink,    'homepages_en.nq',                            ],
#   wikipedia_links:    [:field,      'wikipedia_links_en.nq',                      ],
#   persondata:         [:properties, 'persondata_unredirected_en.nq',              ],
#   yago:               [:joinkey,    'yago_links.nt',                              ],
# }


Wukong::Script.new(Dbpedia::RdfExtractor, nil).run
