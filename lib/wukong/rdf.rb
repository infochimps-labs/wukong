module Wukong
  #
  # Dump wukong object as RDF triples:
  #
  #   <key     attr    val     module Wukong
  #
  # Dump wukong object as RDF triples:
  #
  #   <key>     <attr>    <val> # <extra>
  #
  # Each element of the triple is XML encoded such that it contains no tab,
  # newline or carriage returns, and the three are tab-separated. Any extra
  # fields -- reification info, for instance -- are appended as a comment.
  #
  # This makes the result not only a valid RDF triple file but perfectly
  # palatable to Wukong for further processing.
  #
  module Rdf

    #
    # RDF-formatted date
    #
    def self.encode_datetime dt
      begin
        DateTime.parse(dt).to_s
      rescue ArgumentError => e
        nil
      end
    end

    #
    # Emit a component (subject or object) with the right semantic encoding
    #
    # Use :boolskip if a false property should just be left out.
    #
    def rdf_component val, type
      case type
      when :tweet         then %Q{<http://twitter.com/statuses/show/#{val}.xml>}
      when :user          then %Q{<http://twitter.com/users/show/#{val}.xml>}
      when :bool          then ((!val) || (val==0) || (val=="0")) ? '"false"^^<xsd:boolean>' : '"true"^^<xsd:boolean>'
      when :boolskip      then ((!val) || (val==0) || (val=="0")) ? nil                      : '"true"^^<xsd:boolean>'
      when :int           then %Q{"#{val.to_i}"^^<xsd:integer>}
      when :date          then %Q{"#{TwitterRdf.encode_datetime(val)}"^^<xsd:dateTime>}
      when :str           then %Q{"#{val}"}
      else raise "Don't know how to encode #{type}"
      end
    end

    #
    # Express relationship (predicate) in RDF
    #
    def rdf_pred pred
      case pred
      when :created_at  then %Q{<http://twitter.com/##{pred}>}
      else                   %Q{<http://twitter.com/##{pred}>}
      end
    end

    #
    # RDF Triple string for the given (subject, object, predicate)
    #   http://www.w3.org/TR/rdf-testcases/#ntriples
    #
    def self.rdf_triple subj, pred, obj, comment=nil
      comment = "\t# " + comment.to_s unless comment.blank?
      %Q{%-55s\t%-39s\t%-23s\t.%s} % [subj, pred, obj, comment]
    end

    def mutable?(attr)
      false
    end

    #
    # Extract [subject, predicate, object, (extra)] tuples.
    #
    # (extra) is set to +scraped at+ for #mutable? attributes, blank otherwise.
    #
    def to_rdf3_tuples
      members_with_types.map do |attr, type|
        next if self[attr].blank?
        subj    = rdf_resource
        pred    = rdf_pred(attr)
        obj     = rdf_component(self[attr], type) or next
        comment = scraped_at if mutable?(attr)
        [subj, pred, obj, comment]
      end.compact
    end

    #
    # Convert an object to an rdf triple.
    #
    # Appends scraped at to #mutable? attributes
    #
    def to_rdf3
      to_rdf3_tuples.map do |tuple|
        self.class.rdf_triple tuple
      end.join("\n")
    end

  end
end
>
  #
  #
  module Rdf
    def to_rdf
    end
  end
end
