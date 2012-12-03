#!/usr/bin/env ruby
require_relative './dbpedia_common'
require 'ap'

Settings.define :dbpedia_filetype, description: 'The dbpedia file type ("geo_coordinates", etc) -- taken from input filename if available'

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
    # type descriptions
    dbpedia_class:    'http://dbpedia\.org/class/(?<%s>[^>\s]+)',
    yago_class:       'http://dbpedia\.org/class/yago',
    dbpedia_ontb:     'http://dbpedia\.org/ontology',
    dbpedia_ont:      'http://dbpedia\.org/ontology/(?<%s>[\w\/]+)',
    dbpedia_prop:     'http://dbpedia\.org/property/(?<%s>\w+)',
    dbpedia_rsrc:     "http://dbpedia\\.org/resource/(?<%s>[#{Re::Uri::PCHAR}%%\/]+)",
    wiki_category:    'http://en\.wikipedia\.org/wiki/Category:Futurama?oldid=485425712\\#absolute-line=1',
    wiki_link_id:     'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)\\#absolute-line=(?<%s>\d+)',
    wiki_link_id_sec: 'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)\\#?(?:section=(?<%s>.*?)\&relative-line=(?<%s>\d+))?(?:&?absolute-line=(?<%s>\d+))?',
    purl_desc:        'http://purl\.org/dc/elements/1\.1/(?<%s>description)',
    purl_lang:        'http://purl\.org/dc/elements/1\.1/language',
    purl_subject:     'http://purl\.org/dc/terms/subject',
    rdf_type:         'http://www\.w3\.org/1999/02/22-rdf-syntax-ns\\#type',
    rdf_comment:      'http://www\.w3\.org/2000/01/rdf-schema\\#comment',
    rdf_label:        'http://www\.w3\.org/2000/01/rdf-schema\\#label',
    # external links and sameas'es
    same_as:          'http://www\.w3\.org/2002/07/owl\\#sameAs',
    wordnet_inst:     'http://www\.w3\.org/2006/03/wn/wn20/instances/synset-(?<%s>\w+)-noun-(?<%s>[0-9]+)',
    musicbrainz_rsrc: 'http://zitgist\.com/music/(?<%s>\w+)/(?<%s>[a-f0-9\-]+)',
    nytimes_rsrc:     'http://data\.nytimes\.com/(?<%s>[A-Z0-9]+)',
    geonames_rsrc:    'http://sws\.geonames\.org/(?<%s>\d+)/',
    georss_type:      'http://www\.georss\.org/georss/point',
    wgs_latorlng:     'http://www\.w3\.org/2003/01/geo/wgs84_pos\\#(?:lat|long)',
    # category links
    skos_concept:     'http://www\.w3\.org/2004/02/skos/core\\#(?<%s>[a-zA-Z]+)',
    skos_subject:     'http://www\.w3\.org/2004/02/skos/core\\#subject',
    foaf_homepage:    'http://xmlns\.com/foaf/0\.1/homepage',
    foaf_name:        'http://xmlns\.com/foaf/0\.1/name',
    foaf_topic:       'http://xmlns\.com/foaf/0\.1/(?:isPrimaryTopicOf|primaryTopic)',
    foaf_prop:        'http://xmlns\.com/foaf/0\.1/(?<property>\w+)',
    # property values
    georss_latlng:    '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\\s(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"@\w\w',
    rdf_eol:          '\\.',
    #
    dbpedia_value:    '"(?<%s>(?:\\\"|[^\"]+)*)"\\^\\^<http://dbpedia\.org/datatype/(?<%s>[a-zA-Z]+)>',
    rdf_string:       '"(?<%s>(?:\\\"|[^\"]+)*)"@en',
    rdf_bool:         '\"(?<%s>true|false                        )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>boolean)>',
    rdf_date:         '\"(?<%s>-?\d\d\d\d-\d\d-\d\d              )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>date)>',
    rdf_yearmonth:    '\"(?<%s>-?\d\d\d\d-\d\d                   )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>gYearMonth)>',
    rdf_monthday:     '\"(?<%s>--\d\d-\d\d                       )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>gMonthDay)>',
    rdf_int:          '\"(?<%s>[\+\-]?\d+                        )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>integer|gYear|positiveInteger|nonNegativeInteger)>',
    rdf_float:        '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>float|double)>',
    #
    wikipedia_rsrc:   "http://\\w\\w\\.wikipedia\\.org/wiki/(?<%s>[#{Re::Uri::PCHAR}%%\/]+)",
    url_loose:        '(?<%s>(?:https?|ftp)://(?:[a-zA-Z0-9\-]+\.)+(?:[a-zA-Z\-]+)[^\s>]*)',
    # rdf_value:        '\"(?<%s>-?\d\d\d\d-\d\d-\d\d|-?\d\d\d\d-\d\d|--\d\d-\d\d|[\+\-]?\d+|[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?|true|false)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>integer|date|gYearMonth|gMonthDay|gYear|positiveInteger|nonNegativeInteger|float|double|boolean)>',
    schema_type:      'http://(?<%s>www\\.w3\\.org/2002/07/owl|schema\\.org|dbpedia\\.org/ontology|purl\\.org/ontology|xmlns.com/foaf/0\\.1)[/\#]([^>]+)'
  }

  private
  # lookup regexp in above table, sub in variable names
  def self.r(regexp_name, *args)
    RDF_RES[regexp_name] % args
  end
  public

  MAPPING_INFO = {
    # atomic topic properties
    title:               { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_label)}>                          \s#{r(:rdf_string, :title )}            \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>     \s#{r(:rdf_eol)}  \z}x, },
    page_id:             { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageID>            \s#{r(:rdf_int,    :wikipedia_pageid, :_dtyp)}   \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>     \s#{r(:rdf_eol)}  \z}x, },
    wikipedia_lang:      { re: %r{\A<#{r(:wikipedia_rsrc,  :wikipedia_id)}>         \s<#{r(:purl_lang)}>                          \s#{r(:rdf_string, :lang)}               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    wikipedia_link:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_topic)}>                         \s#{r(:wikipedia_rsrc, :wikipedia_url)}>         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    wikipedia_backlink:  { re: %r{\A<#{r(:wikipedia_rsrc,  :wikipedia_url)}>        \s<#{r(:foaf_topic)}>                         \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>           \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    abstract_short:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_comment)}>                        \s#{r(:rdf_string, :abstract)}            \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>     \s#{r(:rdf_eol)}  \z}x, },
    abstract_long:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/abstract>              \s#{r(:rdf_string, :abstract)}            \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>     \s#{r(:rdf_eol)}  \z}xm, },
    geo_coordinates:     { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:georss_type)}>                        \s#{r(:georss_latlng, :lat, :lng)}               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    geo_coord_skip_a:    { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<http://www\.opengis\.net/gml/_Feature>        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    geo_coord_skip_b:    { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:wgs_latorlng)}>                       \s#{r(:rdf_float, :val, :_dtyp)}                 \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    # links between topics
    page_links:          { re: %r{\A<#{r(:dbpedia_rsrc,    :from_id)}>              \s<#{r(:dbpedia_ontb)}/wikiPageWikiLink>      \s<#{r(:dbpedia_rsrc, :into_id)}>                \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    disambiguations:     { re: %r{\A<#{r(:dbpedia_rsrc,    :generic_wpid)}>         \s<#{r(:dbpedia_ontb)}/wikiPageDisambiguates> \s<#{r(:dbpedia_rsrc, :specific_wpid)}>          \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    redirects:           { re: %r{\A<#{r(:dbpedia_rsrc,    :dupe_id)}>              \s<#{r(:dbpedia_ontb)}/wikiPageRedirects>     \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>           \s#{r(:rdf_eol)}   \z}x, },
    # external links and sameas'es
    external_links:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageExternalLink>  \s<#{r(:url_loose, :weblink_url)}>               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    homepages:           { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_homepage)}>                      \s<#{r(:url_loose, :weblink_url)}>               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    geonames:            { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:geonames_rsrc, :geonames_id)}>           \s#{r(:rdf_eol)}  \z}x, },
    musicbrainz:         { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:musicbrainz_rsrc, :musicbrainz_type, :musicbrainz_id)}>    \s#{r(:rdf_eol)}  \z}x, },
    nytimes:             { re: %r{\A<#{r(:nytimes_rsrc,    :nytimes_id)}>           \s<#{r(:same_as)}>                            \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>           \s#{r(:rdf_eol)}   \z}x, },
    uscensus:            { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:url_loose, :census_url)}>                \s#{r(:rdf_eol)}  \z}x, },
    pnd:                 { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/individualisedPnd>     \s#{r(:rdf_string, :pnd_id)}             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    # category links
    article_categories:  { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:purl_subject)}>                       \s<#{r(:dbpedia_rsrc, :specific_wpid)}>          \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    category_title:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_label)}>                          \s#{r(:rdf_string, :category_title)}     \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    category_skos:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:skos_concept, :skos_relation)}>          \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    category_skos_title: { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_concept, :skos_relation)}>       \s#{r(:rdf_string, :category_title)}                \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x, },
    category_skos_reln:  { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_concept, :skos_relation)}>       \s<#{r(:dbpedia_rsrc, :category_b)}>             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    instance_types:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:dbpedia_ont, :specific_wpid)}>           \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,  },
    # properties
    wordnet:             { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_prop, :property)}>            \s<#{r(:wordnet_inst, :wn_class, :wn_idx)}>      \s#{r(:rdf_eol)}  \z}x, },
    #
    property_str:        { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_string,    :val)            }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_bool:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_bool,      :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_int:        { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_int,       :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_float:      { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_float,     :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_date:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_date,      :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_yearmonth:  { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_yearmonth, :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_monthday:   { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_monthday,  :val, :val_type) }         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    #
    persondata_reln:     { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s<#{r(:dbpedia_rsrc, :into_wpid)}>              \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    persondata_type:     { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<http://xmlns.com/foaf/0\.1/Person>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_foaf:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_prop, :property)}>               \s#{r(:rdf_string, :val)}                        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_desc:       { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:purl_desc, :property)}>               \s#{r(:rdf_string,:name)}                        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    yago:                { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:schema_type, :schema, :schema_type)}>    \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    property_specmap:    { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:dbpedia_value, :val, :units)}    }x, }, #            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}>  \s#{r(:rdf_eol)}  \z}x, },
    # topical_concepts:  { re: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_subject)}>                       \s<#{r(:x, )}> \z},
  }

  MAPPING_FIELDS = {
    # atomic topic properties
    title:               [:page_id, :wp_ns, :wikipedia_id,                 :title,                             ],
    page_id:             [:page_id, :wp_ns, :wikipedia_id,                 :wikipedia_pageid,                  ],
    wikipedia_lang:      [:page_id, :wp_ns, :wikipedia_id,                 :lang,                              ],
    wikipedia_link:      [:page_id, :wp_ns, :wikipedia_id,                 :weblink_url,        :revision_id,  ],
    wikipedia_backlink:  [:page_id, :wp_ns, :wikipedia_id,                 :wikipedia_id2,      :revision_id,  ],
    abstract_short:      [:page_id, :wp_ns, :wikipedia_id,                 :abstract,                          ],
    abstract_long:       [:page_id, :wp_ns, :wikipedia_id,                 :abstract,                          ],
    geo_coordinates:     [:page_id, :wp_ns, :wikipedia_id,                 :lat,                :lng,          ],
    geo_coord_skip_a:    [],
    geo_coord_skip_b:    [],
    # links between topics
    page_links:          [:page_id, :wp_ns, :from_id,                      :into_id,                           ],
    disambiguations:     [:page_id, :wp_ns, :generic_wpid,                 :specific_wpid,                     ],
    redirects:           [:page_id, :wp_ns, :dupe_id,                      :wikipedia_id,                      ],
    # external links and s
    external_links:      [:page_id, :wp_ns, :wikipedia_id, :property,      :weblink_url,                       ],
    homepages:           [:page_id, :wp_ns, :wikipedia_id, :property,      :weblink_url,                       ],
    geonames:            [:page_id, :wp_ns, :wikipedia_id,                 :geonames_id,                       ],
    musicbrainz:         [:page_id, :wp_ns, :wikipedia_id,                 :musicbrainz_type,  :musicbrainz_id,],
    nytimes:             [:page_id, :wp_ns, :wikipedia_id,                 :nytimes_id,                        ],
    uscensus:            [:page_id, :wp_ns, :wikipedia_id,                 :census_url,                        ],
    pnd:                 [:page_id, :wp_ns, :wikipedia_id,                 :pnd_id,                            ],
    # category links
    article_categories:  [:page_id, :wp_ns, :wikipedia_id,                 :specific_wpid,                     ],
    category_title:      [:page_id, :wp_ns, :wikipedia_id,                 :category_title                     ],
    category_skos:       [:page_id, :wp_ns, :wikipedia_id,                 :skos_relation,                     ],
    category_skos_title: [:page_id, :wp_ns, :wikipedia_id, :skos_relation, :category_title,                    ],
    category_skos_reln:  [:page_id, :wp_ns, :wikipedia_id, :skos_relation, :into_wpid,                         ],
    instance_types:      [:page_id, :wp_ns, :wikipedia_id,                 :specific_wpid,                     ],
    # properties
    wordnet:             [:page_id, :wp_ns, :wikipedia_id, :property,      :wn_class,           :wn_idx,       ],
    property_str:        [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                               ],
    property_bool:       [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    property_int:        [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    property_float:      [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    property_date:       [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    property_yearmonth:  [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    property_monthday:   [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :val_type,     ],
    persondata_reln:     [:page_id, :wp_ns, :wikipedia_id, :property,      :into_wpid,                         ],
    persondata_type:     [:page_id, :wp_ns, :wikipedia_id, :property,                                          ],
    property_foaf:       [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                               ],
    property_desc:       [:page_id, :wp_ns, :wikipedia_id, :property,      :name,                              ],
    yago:                [:page_id, :wp_ns, :wikipedia_id,                 :schema,             :schema_type,  ],
    property_specmap:    [:page_id, :wp_ns, :wikipedia_id, :property,      :val,                :units,        ],
    # topical_concepts:  [:page_id, :wp_ns, :wikipedia_id, :skos_subject   :x,                                 ],  #<http://dbpedia.org/resource/Futurama   r(:wiki_category,
  }
  MAPPING_FIELDS.each{|re_name, re| MAPPING_INFO[re_name][:fields] = re }
  SKIPPAPLE_FIELDS = [:flavor, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno, :val_lang, :name_lang, :_dtyp]

  # persondata: {"name"=>12, "description"=>11, "birthPlace"=>17, "deathPlace"=>9, "birthDate"=>10, "deathDate"=>8, "surname"=>10, "givenName"=>10},

  DBPEDIA_FLAVOR_INFO = {
    title:               ['labels_en',                               [:title,              ],  ],
    page_id:             ['page_ids_en',                             [:page_id,            ],  ],
    wikipedia_link:      ['wikipedia_links_en',                      [:wikipedia_links, :wikipedia_backlink, :wikipedia_lang,      ],   ],
    abstract_short:      ['short_abstracts_en',                      [:abstract_short,      ],  ],
    abstract_long:       ['long_abstracts_en',                       [:abstract_long,       ],  ],
    geo_coordinates:     ['geo_coordinates_en',                      [:geo_coordinates, :geo_coord_skip_a, :geo_coord_skip_b, ],        ],
    #                                                                #
    page_links:          ['page_links_unredirected_en',              [:page_links,          ],  ],
    disambiguations:     ['disambiguations_unredirected_en',         [:disambiguations,     ],  ],
    redirects:           ['redirects_transitive_en',                 [:redirects,           ],  ],
    #                                                                #
    external_links:      ['external_links_en',                       [:external_links,      ],  ],
    homepages:           ['homepages_en',                            [:homepages,           ],  ],
    geonames:            ['geonames_links',                          [:geonames,            ],  ],
    musicbrainz:         ['musicbrainz_links',                       [:musicbrainz,         ],  ],
    nytimes:             ['nytimes_links',                           [:nytimes,             ],  ],
    uscensus:            ['uscensus_links',                          [:uscensus,            ],  ],
    pnd:                 ['pnd_en',                                  [:pnd,                 ],  ],
    #                                                                #
    article_categories:  ['article_categories_en',                   [:article_categories,  ],  ],
    category_title:      ['category_labels_en',                      [:category_title,     ],  ],
    category_skos:       ['skos_categories_en',                      [:category_skos,       ],  ],
    category_skos_title: ['skos_categories_en',                      [:category_skos_title, :category_skos_reln ],      ],
    yago:                ['yago_links',                              [:yago,                ],  ],
    instance_types:      ['instance_types_en',                       [:instance_types,      ],  ],
    #                                                                #
    wordnet:             ['wordnet_links',                           [:wordnet,             ],  ],
    persondata:          ['persondata_unredirected_en',              [:persondata_reln, :persondata_type,          ],   ],
    property_specmap:    ['specific_mappingbased_properties_en',     [:property_specmap,    ],  ],
    property_mapped:     ['mappingbased_properties_unredirected_en', [
        :property_str, :property_bool, :property_int,
        :property_float, :property_date, :property_yearmonth, :property_monthday,
        :persondata_reln, :persondata_type, :property_foaf, :property_desc, ],      ],
    topical_concepts:    ['topical_concepts_unredirected_en',        [:topical_concepts,    ],  ],
  }

  class RdfExtractor < Wukong::Streamer::LineStreamer
    include MungingUtils
    attr_accessor :flavor, :kind, :filename, :regexps, :seen_keys, :seen_props

    def initialize(*args)
      Settings[:dbpedia_filetype] ||= Settings[:input_paths].to_s
      Settings[:dbpedia_filetype] = File.basename(Settings[:dbpedia_filetype]).gsub(/[\.\-].*/, '')
      @flavor, flavor_info = DBPEDIA_FLAVOR_INFO.detect{|flavor, (filename, _r)| filename == Settings[:dbpedia_filetype] }
      @kind, @filename, @regexps = flavor_info
      @seen_keys  = Hash.new(0)
      @seen_props = Hash.new(0)
      Log.info ['about me', self.inspect, Settings].join("\t")
    end

    def record_for_flavor(fields, flavor, hsh)
      hsh.merge!( wp_ns: 0, flavor: flavor )

      hsh.except(*fields).except(*SKIPPAPLE_FIELDS).
        each{|key, val| @seen_keys[key] += 1 if val.present? }

      case flavor
      when :geo_coord_skip_a, :geo_coord_skip_b, :persondata_type
        return
      when :property_str
        hsh[:val] = MultiJson.encode(hsh[:val])
      when :abstract_long, :abstract_short
        hsh[:abstract] = MultiJson.encode(hsh[:abstract])
      when :category_label
        hsh[:category_title] = MultiJson.encode(hsh[:category_title])
      when :category_skos_label
        hsh[:category_skos_label] = MultiJson.encode(hsh[:category_title])
      # when :title           then hsh.values_at('', :wp_ns, :wikipedia_id, :title)
      # when :geo_coordinates then hsh.values_at('', :wp_ns, :wikipedia_id, :longitude, :latitude)
      # when :page_links      then hsh.values_at('', :wp_ns, :from_id,      :into_id)
      # else
      #   hsh.values_at(:wikipedia_id)
      end
      seen_props[hsh[:property]] += 1 if hsh[:property].present?

      # , :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno
      hsh.values_at(*fields)
    end

    def after_stream
      Log.info ["Unused keys:     ", seen_keys.inspect ].join("\t")
      Log.info ["Seen properties: ", seen_props.inspect].join("\t")
    end

    def process(line)
      return if line =~ /\A(?:\#|$)/
      if (line =~ /=> \w+\.\w+ <=/) then yield [line] ; return ; end

      MAPPING_INFO.each do |flavor, info|
        next unless mm = info[:re].match(line)
        puts [flavor, line].join("\t")
        yield record_for_flavor(info[:fields], flavor, mm.as_hash)
        return
      end

      puts ['not found:', line].join("\t")
    end
  end
end



Wukong::Script.new(Dbpedia::RdfExtractor, nil).run
