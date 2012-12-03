## Encodings
All SQL dumps are theoretically encoded in UTF-8, but the Wikipedia dumps contain malformed characters. You might see a 'Invalid UTF-8 byte sequence' error when running a Wukong because of this.

To fix this, use `guard_encoding` in `MungingUtils` to filter out malformed characters before attempting to process them. `guard_encoding` replaces all invalid characters with '�'.

If you need to ensure that all characters are valid UTF-8 when piping things around on the command line, then pipe your stream through `char_filter.rb`.

If you need an invalid UTF-8 character, pretty much any single-byte character above \x79 will do. e.g:

    > char = "\x80"
    => "\x80"
    > char.encoding.name
    => "UTF-8"
    > char.valid_encoding?
    => false

[James Gray's blog](http://blog.grayproductions.net/articles/understanding_m17n) is really valuable for further reading on this.

## Dates
Date information should be formatted as follows:

    +----------+--------+--------------------------+-------------+
    | int      | int    | long or float            | int         |
    +----------+--------+--------------------------+-------------+
    | YYYYMMDD | HHMMSS | Seconds since Unix epoch | Day of week |
    +----------+--------+--------------------------+-------------+

Should always be in the UTC time zone.

Hours go from 0 to 23

Months go from 01 to 12

Day of week goes from 0 to 6 (Sunday to Saturday)



## DBpedia



	geocoordinates				wp_ns	wikipedia_id	longitude	latitude			revision_id	article_section	section_lineno	article_lineno
	personnammendatei			wp_ns	wikipedia_id	pnd_id						revision_id	article_section	section_lineno	article_lineno
	disambiguations				wp_ns	wikipedia_id	specific_id					revision_id	article_section	section_lineno	article_lineno
	page_ids      		wp_pageid	wp_ns	wikipedia_id							revision_id	article_section	section_lineno	article_lineno
	redirects     				wp_ns	dupe_wpid  	actual_wpid					revision_id	article_section	section_lineno	article_lineno
	article_categories			wp_ns	wikipedia_id	category_wpid					revision_id	article_section	section_lineno	article_lineno
	categories_skos:       			wp_ns	category_wpid_a	category_wpid_b	a_rel_b 			revision_id	article_section	section_lineno	article_lineno
	abstracts_short:       			wp_ns	wikipedia_id	abstract					revision_id	article_section	section_lineno	article_lineno
	abstracts_long:        			wp_ns	wikipedia_id	abstract					revision_id	article_section	section_lineno	article_lineno
	titles:                			wp_ns	wikipedia_id	title						revision_id	article_section	section_lineno	article_lineno
	nytimes:               			wp_ns	wikipedia_id	nytimes_id					revision_id	article_section	section_lineno	article_lineno
	page_links:            			wp_ns	from_wpid	into_wpid					revision_id	article_section	section_lineno	article_lineno
	external_links:        			wp_ns	wikipedia_id	weblink_url					revision_id	article_section	section_lineno	article_lineno
	homepages:             			wp_ns	wikipedia_id	weblink_url					revision_id	article_section	section_lineno	article_lineno
	musicbrainz:           			wp_ns	wikipedia_id	musicbrainz_id	musicbrainz_type		revision_id	article_section	section_lineno	article_lineno
	properties_map_val:    			wp_ns	wikipedia_id	property	value         	units		revision_id	article_section	section_lineno	article_lineno
	yago:                  			wp_ns	wikipedia_id	yago_id						revision_id	article_section	section_lineno	article_lineno
	persondata:       			wp_ns	wikipedia_id	property	value     	units		revision_id	article_section	section_lineno	article_lineno
	topical_concepts:     			wp_ns	category_wpid	topic_wpid	         			revision_id	article_section	section_lineno	article_lineno
	topical_concepts:			wp_ns	wikipedia_id	is_concept
	# uscensus:            
	instance_types:      			wp_ns	wikipedia_id	category_wpid

	instance_types_en.nq.bz2                        	29-Jun-2012 13:18	        97M	Contains triples of the form $object rdf:type $class from the ontology-based extraction.
	mappingbased_properties_unredirected_en.nq.bz2  	29-Jun-2012 03:11	       251M	High-quality data extracted from Infoboxes using the ontology-based extraction. The predicates in this dataset are in the /ontology/ namespace. Used to be called Mapping Based Properties in previous releases.
	specific_mappingbased_properties_en.nq.bz2      	29-Jun-2012 08:05	        11M	Infobox data from the ontology-based extraction, using units of measurement more convenient for the resource type, e.g. square kilometres instead of square metres for the area of a city.
	labels_en.nq.bz2                                	25-Jul-2012 15:29	       208M	Titles of all Wikipedia Articles in the corresponding language.
	short_abstracts_en.nq.bz2                       	25-Jul-2012 18:29	       382M	Short Abstracts (max. 500 characters long) of Wikipedia articles
	long_abstracts_en.nq.bz2                        	25-Jul-2012 15:33	       682M	Full abstracts of Wikipedia articles, usually the first section.
	geo_coordinates_en.nq.bz2                       	28-Jun-2012 21:25	        20M	Geographic coordinates extracted from Wikipedia.
	homepages_en.nq.bz2                             	29-Jun-2012 13:18	        13M	Links to homepages of persons, organizations etc.
	persondata_unredirected_en.nq.bz2               	29-Jun-2012 04:39	        72M
	article_categories_en.nq.bz2                    	28-Jun-2012 22:23	       249M	Links from concepts to categories using the SKOS vocabulary
	category_labels_en.nq.bz2                       	29-Jun-2012 11:00	        16M	Labels for Categories.
	external_links_en.nq.bz2                        	28-Jun-2012 21:23	       185M	Links to external web pages about a concept.
	page_links_unredirected_en.nq.bz2               	29-Jun-2012 00:15	      1700G     Dataset containing internal links between DBpedia instances. The dataset was created from the internal links between Wikipedia articles. The dataset might be useful for structural analysis, data mining or for ranking DBpedia instances using Page Rank or similar algorithms.
	redirects_transitive_en.nt.bz2   			12-Jul-2012 11:00		92M	Redirects dataset in which multiple redirects have been resolved and redirect cycles have been removed.
	disambiguations_unredirected_en.nq.bz2          	29-Jun-2012 14:49	        15M	Links extracted from Wikipedia disambiguation pages. Since Wikipedia has no syntax to distinguish disambiguation links from ordinary links, DBpedia has to use heuristics.
	page_ids_en.nq.bz2                              	27-Jul-2012 22:58	       216M	Dataset linking a DBpedia resource to the page ID of the Wikipedia article the data was extracted from.
	geonames_links.nt.bz2                            	xx                         	xxM	Links between geographic places in DBpedia and data about them from GeoNames. Links created by Silk link specifications.
	topical_concepts_unredirected_en.nq.bz2         	09-Jul-2012 18:37	         2M
