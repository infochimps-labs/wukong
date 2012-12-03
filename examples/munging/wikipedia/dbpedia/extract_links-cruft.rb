
Settings.define :dbpedia_filetype, description: 'The dbpedia file type ("geo_coordinates", etc) -- taken from input filename if available'

# Settings[:dbpedia_filetype] ||= Settings[:input_paths].to_s
      # Settings[:dbpedia_filetype] = File.basename(Settings[:dbpedia_filetype]).gsub(/[\.\-].*/, '')
      # @flavor, flavor_info = DBPEDIA_FLAVOR_INFO.detect{|flavor, (filename, _r)| filename == Settings[:dbpedia_filetype] }
      # @kind, @filename, @regexps = flavor_info

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
    category_title:      ['category_labels_en',                      [:title,     ],  ],
    category_skos:       ['skos_categories_en',                      [:category_skos_skip, :category_skos_title, :category_skos_reln ],      ],
    #                                                                #
    wordnet:             ['wordnet_links',                           [:wordnet,             ],  ],
    persondata:          ['persondata_unredirected_en',              [:persondata_reln, :persondata_type,          ],   ],
    yago:                ['yago_links',                              [:yago,                :instance_type_a, :instance_type_b,  ],  ],
    instance_types:      ['instance_types_en',                       [:yago,                :instance_type_a, :instance_type_b,  ],  ],
    property_specmap:    ['specific_mappingbased_properties_en',     [:property_specmap,    ],  ],
    property_mapped:     ['mappingbased_properties_unredirected_en', [
        :property_str, :property_bool, :property_int,
        :property_float, :property_date, :property_yearmonth, :property_monthday,
        :persondata_reln, :persondata_type, :property_foaf, :property_desc, ],      ],
    topical_concepts:    ['topical_concepts_unredirected_en',        [:topical_concepts,    ],  ],
  }

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
