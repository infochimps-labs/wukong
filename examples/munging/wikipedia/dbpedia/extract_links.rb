#!/usr/bin/env ruby
require_relative './dbpedia_common'

# Notes:
#
# * disambiguation: `generic disambiguates specifics` -- `["Alien", "Alien_(law)"]` and `["Alien", "Alien_(film)"]`
# * redirects:      `dupe    redirects to  actual`    -- `["Oxygen-13", "Isotopes_of_oxygen"]`
# * page_link:      `from    links to      into`      -- `["Achilles", "Greeks"]

module Dbpedia

  DECIMAL_NUM_RE  = '[\-\+\d]+\.\d+'
  URI_PATHCHARS   = '\w\-\.\'~!$&()*+,;=:@'
  # all backslash-escaped character, or non-quotes, up to first quote
  DBLQ_STRING_C   = '"(?<%s>(?:\\.|[^\"])*)"'

  # output flavors:
  #
  # :abstract_long   :abstract_short      :category :category_reln  :disambiguation
  # :external_link   :geo_coordinates     :homepage :instance_of    :page_id :page_link
  # :persondata_reln :property :redirects :sameas   :subject :title :wikipedia_link
  #

  MAPPING_INFO = {
    # atomic topic properties
    title:               { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,  :title,                                      ],  },
    page_id:             { kind: :page_id,             fields: [:page_id, :wp_ns, :wikipedia_id, :wikipedia_pageid,                           ],  },
    abstract_short:      { kind: :abstract_short,      fields: [:page_id, :wp_ns, :wikipedia_id, :abstract,                                   ],  },
    abstract_long:       { kind: :abstract_long,       fields: [:page_id, :wp_ns, :wikipedia_id, :abstract,                                   ],  },
    wikipedia_lang:      { kind: :skip,                fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :url,     :slug,  :lang,                  ],  },
    wikipedia_link:      { kind: :wikipedia_link,      fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :url,     :slug,  :revision_id,           ],  },
    wikipedia_backlink:  { kind: :skip,                fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :url,     :slug,  :revision_id,           ],  },
    geo_coordinates:     { kind: :geo_coordinates,     fields: [:page_id, :wp_ns, :wikipedia_id, :lat,        :lng,     :quadkey              ],  },
    geo_coord_skip_a:    { kind: :skip,                fields: [],      },
    geo_coord_skip_b:    { kind: :skip,                fields: [],      },
    # links between topics
    page_link:           { kind: :page_link,           fields: [:page_id, :wp_ns, :from_id,      :relation,   :into_id,                       ],  },
    disambiguation:      { kind: :disambiguation,      fields: [:page_id, :wp_ns, :generic_wpid, :relation,   :specific_wpid,                 ],  },
    redirects:           { kind: :redirects,           fields: [:page_id, :wp_ns, :dupe_id,      :relation,   :wikipedia_id,                  ],  },
    # external links and sameas'es
    external_link:       { kind: :external_link,       fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :weblink_url,                   ],  },
    homepage:            { kind: :homepage,            fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :weblink_url,                   ],  },
    geonames:            { kind: :sameas,              fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :geonames_id,                   ],  },
    musicbrainz:         { kind: :sameas,              fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :musicbrainz_type,  :musicbrainz_id,], },
    nytimes:             { kind: :sameas,              fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :nytimes_id,                    ],  },
    pnd:                 { kind: :sameas,              fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :pnd_id,                        ],  },
    uscensus:            { kind: :sameas,              fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :country_id, :state_id, :kind, :adm2_id, :adm3_id, :adm4_id],  },
    # category links
    category_skos_type:  { kind: :instance_of,         fields: [:page_id, :wp_ns, :wikipedia_id, :scheme,     :obj_class                      ],  },
    category_skos_title: { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :val_type,   :category_title,   ],  },
    category:            { kind: :category,            fields: [:page_id, :wp_ns, :wikipedia_id, :flavor,     :specific_wpid,                 ],  },
    category_subject:    { kind: :subject,             fields: [:page_id, :wp_ns, :wikipedia_id, :scheme,     :into_wpid,                     ],  },
    category_reln:       { kind: :category_reln,       fields: [:page_id, :wp_ns, :wikipedia_id, :relation,   :into_wpid,                     ],  },
    # properties
    wordnet:             { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :wn_reln,    :wn_class,   :wn_pos, :wn_idx,  ],  },
    property_bool:       { kind: :property_bool,       fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_year:       { kind: :property_year,       fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_int:        { kind: :property_int,        fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_float:      { kind: :property_float,      fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_date:       { kind: :property_date,       fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_yearmonth:  { kind: :property_yearmonth,  fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_monthday:   { kind: :property_monthday,   fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_str:        { kind: :property_str,        fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    #
    persondata_reln:     { kind: :persondata_reln,     fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :into_wpid,                     ],  },
    # persondata_type:   { kind: :# persondata_type,   fields: [:page_id, :wp_ns, :wikipedia_id, :property,                                   ],  },
    property_foaf:       { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :val,              ],  },
    property_desc:       { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :val_type,   :name,             ],  },
    yago:                { kind: :category,            fields: [:page_id, :wp_ns, :wikipedia_id, :scheme,     :obj_class,                     ],  },
    instance_type_a:     { kind: :instance_of,         fields: [:page_id, :wp_ns, :wikipedia_id, :scheme,     :obj_class,                     ],  },
    instance_type_b:     { kind: :instance_of,         fields: [:page_id, :wp_ns, :wikipedia_id, :scheme,     :obj_class,                     ],  },
    property_specmap:    { kind: :property,            fields: [:page_id, :wp_ns, :wikipedia_id, :property,   :units,        :val,            ],  },
    # topical_concepts:  { kind: :# topical_concepts,  fields: [:page_id, :wp_ns, :wikipedia_id, :skos_subject   :x,                          ],  },
  }

  RDF_RES = {
    # type descriptions
    dbpedia_class:    'http://dbpedia\.org/class/(?<%s>[^>\s]+)',
    dbpedia_ontb:     'http://dbpedia\.org/ontology',
    dbpedia_ont:      'http://dbpedia\.org/ontology/(?<%s>[\w\/]+)',
    dbpedia_prop:     'http://dbpedia\.org/property/(?<%s>\w+)',
    dbpedia_rsrc:     'http://dbpedia\.org/resource/(?<%s>['           + URI_PATHCHARS + '%%\/]+)',
    yago_class:       'http://dbpedia\.org/class/(?<%s>yago)/(?<%s>['  + URI_PATHCHARS + '%%\/]+)',
    wikipedia_rsrc:   '(?<%s>http://\w\w\.wikipedia\.org/wiki/(?<%s>[' + URI_PATHCHARS + '%%\/]+))',
    wiki_category:    'http://en\.wikipedia\.org/wiki/Category:Futurama?oldid=485425712\\#absolute-line=1',
    wiki_link_id:     'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)(?:\\#absolute-line=(?<%s>\d+))?',
    wiki_link_id_sec: 'http://en\.wikipedia\.org/wiki/(?<%s>[^\?]+)\?oldid=(?<%s>\d+)\\#?(?:section=(?<%s>.*?)\&relative-line=(?<%s>\d+))?(?:&?absolute-line=(?<%s>\d+))?',
    purl_desc:        'http://purl\.org/dc/elements/1\.1/(?<%s>description)',
    purl_lang:        'http://purl\.org/dc/elements/1\.1/language',
    purl_subject:     'http://purl\.org/dc/terms/subject',
    rdf_type:         'http://www\.w3\.org/1999/02/22-rdf-syntax-ns\\#type',
    rdf_comment:      'http://www\.w3\.org/2000/01/rdf-schema\\#comment',
    rdf_label:        'http://www\.w3\.org/2000/01/rdf-schema\\#label',
    # external links and sameas'es
    same_as:          'http://www\.w3\.org/2002/07/owl\\#sameAs',
    wordnet_inst:     'http://www\.w3\.org/2006/03/wn/wn20/instances/(?<%s>synset)-(?<%s>\w+)-(?<%s>noun)-(?<%s>[0-9]+)',
    musicbrainz_rsrc: 'http://zitgist\.com/music/(?<%s>\w+)/(?<%s>[a-f0-9\-]+)',
    nytimes_rsrc:     'http://data\.nytimes\.com/(?<%s>[A-Z0-9]+)',
    geonames_rsrc:    'http://sws\.geonames\.org/(?<%s>\d+)/',
    georss_type:      'http://www\.georss\.org/georss/point',
    wgs_latorlng:     'http://www\.w3\.org/2003/01/geo/wgs84_pos\\#(?:lat|long)',
    #                  http://www.rdfabout.com/rdf/usgov/geo/  us     /     ak       /    counties   /bethel_area  /an_subarea   /aniak          >
    uscensus_url:     'http://www.rdfabout.com/rdf/usgov/geo/(?<%s>us)/(?<%s>\w\w)(?:/(?<%s>counties)/(?<%s>\w+)(?:/(?<%s>\w+)\/?(?<%s>\w+)?)?)?',
    # category links
    skos_subject:     'http://www\.w3\.org/2004/02/skos/core\\#subject',
    skos_concept:     'http://www\.w3\.org/2004/02/skos/core\\#(?<%s>[a-zA-Z]+)',
    foaf_homepage:    'http://xmlns\.com/foaf/0\.1/homepage',
    foaf_name:        'http://xmlns\.com/foaf/0\.1/name',
    foaf_topic:       'http://xmlns\.com/foaf/0\.1/(?:isPrimaryTopicOf|primaryTopic)',
    foaf_prop:        'http://xmlns\.com/foaf/0\.1/(?<property>\w+)',
    # property values
    georss_latlng:    '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\\s(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"@\w\w',
    rdf_eol:          '\\.',
    #
    rdf_bool:         '\"(?<%s>true|false                        )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>boolean)>',
    rdf_date:         '\"(?<%s>-?\d\d\d\d-\d\d-\d\d              )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>date)>',
    rdf_yearmonth:    '\"(?<%s>-?\d\d\d\d-\d\d                   )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>gYearMonth)>',
    rdf_monthday:     '\"(?<%s>--\d\d-\d\d                       )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>gMonthDay)>',
    rdf_int:          '\"(?<%s>[\+\-]?\d+                        )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>integer|positiveInteger|nonNegativeInteger)>',
    rdf_year:         '\"(?<%s>[\+\-]?\d+                        )\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>gYear)>',
    rdf_float:        '\"(?<%s>[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>float|double)>',
    # all backslash-escaped character, or non-quotes, up to first quote
    rdf_string:       '"(?<%s>(?:\\\\.|[^\"])*)"@en',
    dbpedia_value:    '"(?<%s>(?:\\\\.|[^\"])*)"\\^\\^<http://dbpedia\.org/datatype/(?<%s>[a-zA-Z]+)>',
    #
    url_loose:        '(?<%s>(?:https?|ftp)://(?:[a-zA-Z0-9\-]+\.)+(?:[a-zA-Z\-]+)[^\s>]*)',
    # rdf_value:        '\"(?<%s>-?\d\d\d\d-\d\d-\d\d|-?\d\d\d\d-\d\d|--\d\d-\d\d|[\+\-]?\d+|[\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?|true|false)\"\\^\\^<http://www\.w3\.org/2001/XMLSchema\\#(?<%s>integer|date|gYearMonth|gMonthDay|gYear|positiveInteger|nonNegativeInteger|float|double|boolean)>',
    schema_type:      'http://(?<%s>www\\.w3\\.org/2002/07/owl|schema\\.org|dbpedia\\.org/ontology|purl\\.org/ontology|xmlns.com/foaf/0\\.1)[/\\#](?<%s>[^>]+)'
  }

  SCHEMA_SCHEMES = {
    'www.w3.org/2002/07/owl' => 'owl',
    'schema.org'             => 'schemaorg',
    'dbpedia.org/ontology'   => 'dbpedia',
    'purl.org/ontology'      => 'purl',
    'xmlns.com/foaf/0.1'     => 'foaf'
  }

  # lookup regexp in above table, sub in variable names
  private
  def self.r(regexp_name, *args)
    RDF_RES[regexp_name] % args
  end
  public

  MAPPING_RES = {
    # atomic topic properties
    title:               %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_label)}>                          \s#{r(:rdf_string, :title )}                   \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>                                        \s#{r(:rdf_eol)}  \z}x,
    page_id:             %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageID>            \s#{r(:rdf_int,    :wikipedia_pageid, :_dtyp)} \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>                                        \s#{r(:rdf_eol)}  \z}x,
    wikipedia_lang:      %r{\A<#{r(:wikipedia_rsrc,  :url, :slug)}>         \s<#{r(:purl_lang)}>                          \s#{r(:rdf_string, :lang)}                       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    wikipedia_link:      %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_topic)}>                         \s<#{r(:wikipedia_rsrc, :url, :slug)}>         \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    wikipedia_backlink:  %r{\A<#{r(:wikipedia_rsrc,  :url, :slug)}>        \s<#{r(:foaf_topic)}>                         \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    abstract_short:      %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_comment)}>                        \s#{r(:rdf_string, :abstract)}                 \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>                                        \s#{r(:rdf_eol)}  \z}x,
    abstract_long:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/abstract>              \s#{r(:rdf_string, :abstract)}                 \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>                                        \s#{r(:rdf_eol)}  \z}xm,
    geo_coordinates:     %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:georss_type)}>                        \s#{r(:georss_latlng, :lat, :lng)}             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    geo_coord_skip_a:    %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<http://www\.opengis\.net/gml/_Feature>      \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    geo_coord_skip_b:    %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:wgs_latorlng)}>                       \s#{r(:rdf_float, :val, :_dtyp)}               \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    # links between topic
    page_link:           %r{\A<#{r(:dbpedia_rsrc,    :from_id)}>              \s<#{r(:dbpedia_ontb)}/wikiPageWikiLink>      \s<#{r(:dbpedia_rsrc, :into_id)}>              \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    disambiguation:      %r{\A<#{r(:dbpedia_rsrc,    :generic_wpid)}>         \s<#{r(:dbpedia_ontb)}/wikiPageDisambiguates> \s<#{r(:dbpedia_rsrc, :specific_wpid)}>        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    redirects:           %r{\A<#{r(:dbpedia_rsrc,    :dupe_id)}>              \s<#{r(:dbpedia_ontb)}/wikiPageRedirects>     \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>                                                                                                                       \s#{r(:rdf_eol)}   \z}x,
    # external links and sameas'es
    external_link:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/wikiPageExternalLink>  \s<#{r(:url_loose, :weblink_url)}>             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    homepage:            %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_homepage)}>                      \s<#{r(:url_loose, :weblink_url)}>             \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    geonames:            %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:geonames_rsrc, :geonames_id)}>                                                                                                                       \s#{r(:rdf_eol)}  \z}x,
    musicbrainz:         %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:musicbrainz_rsrc, :musicbrainz_type, :musicbrainz_id)}>                                                                                              \s#{r(:rdf_eol)}  \z}x,
    nytimes:             %r{\A<#{r(:nytimes_rsrc,    :nytimes_id)}>           \s<#{r(:same_as)}>                            \s<#{r(:dbpedia_rsrc, :wikipedia_id)}>                                                                                                                       \s#{r(:rdf_eol)}   \z}x,
    uscensus:            %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:same_as)}>                            \s<#{r(:uscensus_url, :country_id, :state_id, :kind, :adm2_id, :adm3_id, :adm4_id)}>                                                                         \s#{r(:rdf_eol)}  \z}x,
    pnd:                 %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ontb)}/individualisedPnd>     \s#{r(:rdf_string, :pnd_id)}                   \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    # category links
    category:            %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:purl_subject)}>                       \s<#{r(:dbpedia_rsrc, :specific_wpid)}>        \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    category_skos_type:  %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:skos_concept, :obj_class)}>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    category_subject:    %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_subject, :relation)}>            \s<#{r(:dbpedia_rsrc, :into_wpid)}>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    category_reln:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_concept, :relation)}>            \s<#{r(:dbpedia_rsrc, :into_wpid)}>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    category_skos_title: %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_concept, :relation)}>            \s#{r(:rdf_string, :category_title)}           \s<#{r(:wiki_link_id, :wikipedia_id2, :revision_id, :article_lineno)}>                                        \s#{r(:rdf_eol)}  \z}x,
    # properties
    wordnet:             %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_prop, :property)}>            \s<#{r(:wordnet_inst, :wn_reln, :wn_class, :wn_pos, :wn_idx)}>                                                                                               \s#{r(:rdf_eol)}  \z}x,
    #
    property_bool:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_bool,      :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_int:        %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_int,       :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_float:      %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_float,     :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_date:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_date,      :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_yearmonth:  %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_yearmonth, :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_monthday:   %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_monthday,  :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_year:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_year,      :val, :val_type) }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_str:        %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:rdf_string,    :val)            }       \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    #
    persondata_reln:     %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s<#{r(:dbpedia_rsrc, :into_wpid)}>            \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_foaf:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:foaf_prop, :property)}>               \s#{r(:rdf_string, :val)}                      \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_desc:       %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:purl_desc, :property)}>               \s#{r(:rdf_string,:name)}                      \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    yago:                %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:yago_class,  :scheme, :obj_class)}>                                                                                                                  \s#{r(:rdf_eol)}  \z}x,
    instance_type_a:     %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:dbpedia_ont,          :obj_class)}>    \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    instance_type_b:     %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:rdf_type)}>                           \s<#{r(:schema_type, :org,    :obj_class)}>    \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    property_specmap:    %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:dbpedia_ont, :property)}>             \s#{r(:dbpedia_value, :val, :units)}           \s<#{r(:wiki_link_id_sec, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno)}> \s#{r(:rdf_eol)}  \z}x,
    # topical_concepts:  %r{\A<#{r(:dbpedia_rsrc,    :wikipedia_id)}>         \s<#{r(:skos_subject)}>                       \s<#{r(:x, )}> \z},
  }
  MAPPING_RES.each{|re_name, re| MAPPING_INFO[re_name][:re] = re }
  SKIPPAPLE_FIELDS = [:flavor, :wikipedia_id2, :revision_id, :article_section, :section_lineno, :article_lineno, :val_lang, :name_lang, :_dtyp]

  class RdfExtractor < Wukong::Streamer::LineStreamer
    include Wu::Munging::Utils
    attr_accessor :flavor, :kind, :filename, :regexps, :seen_keys, :seen_props

    def initialize(*args)
      @seen_keys  = Hash.new(0)
      @seen_props = Hash.new(0)
    end

    def coerce_int(  hsh, field) ; hsh[field] = (hsh[field].present? ? Integer(hsh[field]) : nil) ; end
    def coerce_float(hsh, field) ; hsh[field] = (hsh[field].present? ? Float(hsh[field])   : nil) ; end

    def record_for_flavor(kind, fields, flavor, hsh)
      hsh.merge!( kind: kind, flavor: flavor, wp_ns: 0 )
      return if kind == :skip

      case flavor
      when :property_str, :property_foaf   then  hsh[:val] = MultiJson.encode(hsh[:val])
      when :abstract_long, :abstract_short then  hsh[:abstract] = MultiJson.encode(hsh[:abstract])
      when :title                          then  hsh[:title] = MultiJson.encode(hsh[:title]) ; hsh[:property] = 'title'
      when :category_skos_title            then  hsh[:category_title] = MultiJson.encode(hsh[:category_title])
      when :category_skos_type then hsh[:scheme] = 'skos'
      when :category_subject   then hsh[:scheme] = 'subject'
      when :instance_type_a    then hsh[:scheme] = 'dbpedia'
      when :instance_type_b
        hsh[:scheme] = SCHEMA_SCHEMES[hsh.delete(:org)]
        return if hsh[:scheme] == 'owl'
      when :wikipedia_link, :wikipedia_backlink
        raise "Titles disagree!" unless hsh[:slug] == hsh[:wikipedia_id]

      when :property_float then coerce_float(hsh, :val)
      when :property_int   then coerce_int(hsh, :val)
      when :geo_coordinates
        coerce_float(hsh, :lng)
        coerce_float(hsh, :lat)
        hsh[:quadkey] = Wu::Geo::Geolocation.point_to_quadkey(hsh[:lng], hsh[:lat]) if (hsh[:lng] && hsh[:lat])
      end
      #
      # note the properties and fields we've seen
      hsh.except(*fields).except(*SKIPPAPLE_FIELDS).
        each{|key, val| @seen_keys[key] += 1 if val.present? }
      seen_props[hsh[:property]] += 1 if hsh[:property].present?
      #
      sanity_check(hsh)
      [kind] + hsh.values_at(*fields)
    end

    def sanity_check(hsh)
      hsh.each{|key,val| raise if CONTROL_CHARS_RE =~ val.to_s }
    end

    def extract_record(rdf_line)
      MAPPING_INFO.each do |flavor, info|
        next unless mm = info[:re].match(rdf_line)
        return record_for_flavor(info[:kind], info[:fields], flavor, mm.as_hash)
      end
      Log.warn ['not found:', line].join("\t")
      return nil
    end

    def after_stream
      Log.info ["seen keys:", seen_keys.inspect, "seen props:", seen_props.inspect].join("\t")
    end

    def process(line)
      return if line =~ /\A(?:\#|$|==>.*<==)/
      result = extract_record(line) or return
      yield result
    rescue StandardError => err
      Log.warn [err.class, err.message, line]
    end
  end
end

Wukong::Script.new(Dbpedia::RdfExtractor, nil).run
