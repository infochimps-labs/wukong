require 'wukong'
require 'gorillib/hash/zip'

module Gorillib
  module Factory

    class XmlInteger
      def receive(rec)
        if rec.is_a?(String) && rec =~ %r{"(\d+)"^^<http://www.w3.org/2001/XMLSchema\#integer>}
          rec = $1
        end
        super(rec)
      end
    end

  end
end

module Wikipedia

  module Dbpedia
    class DbpediaModel
      include Gorillib::Model
    end
    class Topic < DbpediaModel
      field :wikipedia_id,   Integer,  position: 0, doc: "Topic's Wikipedia Numerical ID"
      field :name,           String,   position: 1, doc: "Topic Name"

      field :long_abstract,  String,   doc: "Topic Name"

    end
    class PageLink < DbpediaModel
      field :from,         String,   position: 0, doc: "Topic containing the link"
      field :into,         String,   position: 1, doc: "Topic linked to"
      field :locn_sec,     String,   position: 2, doc: "Section in from page with the link"
      field :locn_rel,     Integer,  position: 3, doc: "Line number within given section of from page"
      field :locn_abs,     Integer,  position: 4, doc: "Line number within all of from page"
    end
  end

  module WpPageviews
    class Pageview
      include Gorillib::Model
      #
      field :lang,         Symbol
      field :project,      Symbol
      field :count,        Integer
      field :bytes_sent,   Integer
      field :wikipedia_id, Integer
      field :name,         String
    end
  end
end

module Wikipedia
  module Dbpedia

    #
    # [named captures](http://ruby.runpaint.org/regexps#captures)
    #
    class RegexMunger < Wukong::Processor
      class_attribute :matcher

      def bad_record(reason, *args)
        warn [reason, self.inspect, args.map{|arg| arg.inspect[0..1000]}].flatten.join("\t")
      end

      def match_names
        @match_names ||= matcher.names.map(&:to_sym)
      end

      def process(rec)
        mm = matcher.match(rec)
        if not mm then bad_record('no match', rec) ; p matcher;  return ; end
        result = Hash.zip(match_names, mm.captures)
        if not validate(result) then bad_record('inconsistent contents', rec, result) ; return ; end
        result
      end
    end

    class NthreeMunger < RegexMunger
      def capture_integer(capture_name) %Q{"(?<#{capture_name}>\\d+)"^^<http://www.w3.org/2001/XMLSchema\#integer>} ; end
      TOPIC_NAME = %Q{<http://dbpedia.org/resource/(?<name>[^>]+)>}
      PAGE_NAME  = %Q{<http://(?<wp_proj_host>en.wikipedia.org)/wiki/(?<page_name>[^>\#]+)\#>}
    end

    # # <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Athena> <http://en.wikipedia.org/wiki/Achilles#section=Achilles+in+the+%27%27Iliad%27&relative-line=17&absolute-line=72> .

    # <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/abstract> "In Greek mythology, Achilles (...)"@en <http://en.wikipedia.org/wiki/Achilles#> .
    class RawLongAbstract < NthreeMunger
      self.matcher = %r{\A #{TOPIC_NAME}\s <http://dbpedia.org/ontology/abstract>\s \"(?<long_abstract>.*)\"@en\s #{PAGE_NAME}\s \.\z}x
      def validate(hsh) (hsh[:page_name] == hsh[:name]) ; end
    end

    # <http://dbpedia.org/resource/Amsterdam> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Cities_in_the_Netherlands> <http://en.wikipedia.org/wiki/Amsterdam#section=External+link&relative-line=33&absolute-line=1031> .
    class RawArticleCategory < NthreeMunger
      self.matcher = %r{\A
          #{TOPIC_NAME}\s
          <http://purl.org/dc/terms/subject>\s
          <http://dbpedia.org/resource/(?<category>Category:[^>]+)>\s
          <http://(?<wp_proj_host>en.wikipedia.org)/wiki/(?<page_name>[^>]+)
            \#section=(?<locn_sec>[^>&]+)
            \&relative-line=(?<locn_rel>\d+)
            \&absolute-line=(?<locn_abs>\d+)
            >\s
          \.\z}x
      def validate(hsh) (hsh[:page_name] == hsh[:name]) ; end
    end

    # <http://dbpedia.org/resource/Category:Algebra> <http://www.w3.org/2000/01/rdf-schema#label> "Algebra"@en <http://en.wikipedia.org/wiki/Category:Algebra#> .
    class RawCategoryLabel < NthreeMunger
      self.matcher = %r{\A#{TOPIC_NAME}\s <http://www.w3.org/2000/01/rdf-schema\#label>\s \"(?<title>.*)\"@en\s  #{PAGE_NAME} \.\z}x
      def validate(hsh) (hsh[:page_name] == hsh[:name]) && (hsh[:name] =~ /^Category:/) ; end
    end

    # # <http://en.wikipedia.org/wiki/AccessibleComputing> <http://dbpedia.org/ontology/wikiPageID> "10"^^<http://www.w3.org/2001/XMLSchema#integer> <http://en.wikipedia.org/wiki/AccessibleComputing#> .
    class RawPageId
    end
    # <http://dbpedia.org/resource/Alabama> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.opengis.net/gml/_Feature> <http://en.wikipedia.org/wiki/Alabama#> .
    # <http://dbpedia.org/resource/Alabama> <http://www.w3.org/2003/01/geo/wgs84_pos#lat> "33.0"^^<http://www.w3.org/2001/XMLSchema#float> <http://en.wikipedia.org/wiki/Alabama#> .
    # <http://dbpedia.org/resource/Alabama> <http://www.w3.org/2003/01/geo/wgs84_pos#long> "-86.66666666666667"^^<http://www.w3.org/2001/XMLSchema#float> <http://en.wikipedia.org/wiki/Alabama#> .
    # <http://dbpedia.org/resource/Alabama> <http://www.georss.org/georss/point> "33.0 -86.66666666666667"@en <http://en.wikipedia.org/wiki/Alabama#> .

    # disambiguations_en.nq:    <http://dbpedia.org/resource/Albert_III> <http://dbpedia.org/ontology/wikiPageDisambiguates> <http://dbpedia.org/resource/Albrecht_III_Achilles,_Elector_of_Brandenburg> <http://en.wikipedia.org/wiki/Albert_III#absolute-line=5> .
    # labels_en.nq:             <http://dbpedia.org/resource/Achilles> <http://www.w3.org/2000/01/rdf-schema#label> "Achilles"@en <http://en.wikipedia.org/wiki/Achilles#> .
    # long_abstracts_en.nq:     <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/abstract> "In Greek mythology, Achilles was a Greek hero of the Trojan War, the central character and the greatest warrior of Homer's Iliad. Achilles was the most handsome of the heroes assembled against Troy. Later legends (beginning with a poem by Statius in the 1st century AD) state that Achilles was invulnerable in all of his body except for his heel. As he died because of a small wound on his heel, the term \"Achilles' heel\" has come to mean a person's principal weakness."@en <http://en.wikipedia.org/wiki/Achilles#> .
    # page_ids_en.nq:           <http://en.wikipedia.org/wiki/Achilles> <http://dbpedia.org/ontology/wikiPageID> "305"^^<http://www.w3.org/2001/XMLSchema#integer> <http://en.wikipedia.org/wiki/Achilles#> .
    # page_links_en.nq:         <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Category:Thessalians_in_the_Trojan_War> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=17&absolute-line=254> .
    # redirects_en.nq:          <http://dbpedia.org/resource/Albert_Archilles> <http://dbpedia.org/ontology/wikiPageRedirects> <http://dbpedia.org/resource/Albrecht_III_Achilles,_Elector_of_Brandenburg> <http://en.wikipedia.org/wiki/Albert_Archilles#> .
    # revisions_en.nq:          <http://en.wikipedia.org/wiki/Achilles> <http://dbpedia.org/ontology/wikiPageRevisionID> "440701795"^^<http://www.w3.org/2001/XMLSchema#integer> <http://en.wikipedia.org/wiki/Achilles#> .
    # topic_signatures_en.tsv:  Achilles        +"Achilles" his he greek

    # article_categories_en.nq: <http://dbpedia.org/resource/Achilles> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Characters_in_the_Iliad> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=11&absolute-line=248> .
    # article_categories_en.nq: <http://dbpedia.org/resource/Achilles> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Kings_of_the_Myrmidons> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=12&absolute-line=249> .
    # article_categories_en.nq: <http://dbpedia.org/resource/Achilles> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Thessalians_in_the_Trojan_War> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=17&absolute-line=254> .
    # external_links_en.nq:     <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageExternalLink> <http://ancientrome.ru/art/artworken/result.htm?alt=Achilles&pnumber=20> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=6&absolute-line=243> .
    # external_links_en.nq:     <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageExternalLink> <http://www.pelasgians.bigpondhosting.com/website1/04_01.htm> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=5&absolute-line=242> .
    # external_links_en.nq:     <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageExternalLink> <http://www.historyguide.org/ancient/troy.html> <http://en.wikipedia.org/wiki/Achilles#section=External+link&relative-line=4&absolute-line=241> .
    # wikipedia_links_en.nq:    <http://dbpedia.org/resource/Achilles> <http://xmlns.com/foaf/0.1/page> <http://en.wikipedia.org/wiki/Achilles> <http://en.wikipedia.org/wiki/Achilles#> .
    # wikipedia_links_en.nq:    <http://en.wikipedia.org/wiki/Achilles> <http://xmlns.com/foaf/0.1/primaryTopic> <http://dbpedia.org/resource/Achilles> <http://en.wikipedia.org/wiki/Achilles#> .
    # wikipedia_links_en.nq:    <http://en.wikipedia.org/wiki/Achilles> <http://purl.org/dc/elements/1.1/language> "en"@en <http://en.wikipedia.org/wiki/Achilles#> .
    # flickrwrapper_links.nt:   <http://www4.wiwiss.fu-berlin.de/flickrwrappr/photos/Achilles>   <http://www.w3.org/2002/07/owl#sameAs>  <http://dbpedia.org/resource/Achilles> .
    # images_en.nq:             <http://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Leon_Benouville_The_Wrath_of_Achilles.jpg/200px-Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://purl.org/dc/elements/1.1/rights> <http://en.wikipedia.org/wiki/File:Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://en.wikipedia.org/wiki/Achilles#absolute-line=2> .
    # images_en.nq:             <http://upload.wikimedia.org/wikipedia/commons/c/cf/Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://purl.org/dc/elements/1.1/rights> <http://en.wikipedia.org/wiki/File:Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://en.wikipedia.org/wiki/Achilles#absolute-line=2> .
    # images_en.nq:             <http://upload.wikimedia.org/wikipedia/commons/c/cf/Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://xmlns.com/foaf/0.1/thumbnail> <http://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Leon_Benouville_The_Wrath_of_Achilles.jpg/200px-Leon_Benouville_The_Wrath_of_Achilles.jpg> <http://en.wikipedia.org/wiki/Achilles#absolute-line=2> .
    # page_links_en.nq:         <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Athena> <http://en.wikipedia.org/wiki/Achilles#section=Achilles+in+the+%27%27Iliad%27&relative-line=17&absolute-line=72> .
    # page_links_en.nq:         <http://dbpedia.org/resource/Achilles> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Hera> <http://en.wikipedia.org/wiki/Achilles#section=Achilles+in+the+%27%27Iliad%27&relative-line=17&absolute-line=72> .
    # yago_links.nt:            <http://dbpedia.org/resource/Achilles> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/class/yago/PeopleOfTheTrojanWar> .
    # yago_links.nt:            <http://dbpedia.org/resource/Achilles> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/class/yago/KingsOfTheMyrmidons> .

  end
end

# processor = Wikipedia::Dbpedia::RawLongAbstract.new
# processor = Wikipedia::Dbpedia::RawArticleCategory.new
processor = Wikipedia::Dbpedia::RawCategoryLabel.new
$stdin.each do |line|
  result = processor.process(line.chomp) or next
  puts result
end
