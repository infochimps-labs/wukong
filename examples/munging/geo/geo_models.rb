module Geo

  class Place
    include Gorillib::Model
    include Gorillib::Model::Indexable

    field :geonames_id,       String
    field :country_id,        String,  doc: "ISO 3166 2-letter alphanumeric id ('us', 'mx', etc). Must be lowercase"
    field :admin1_id,         String
    field :feature_cat,       String
    field :feature_subcat,    String
    #
    field :name,              String
    #
    field :timezone,          String
    field :elevation,         Float
    field :longitude,         Float
    field :latitude,          Float
    #
    field :alternate_names,   String, default: ""

    def names
      ([name] + alternate_names.split("|")).compact_blank
    end

    def coordinates
      { longitude: longitude, latitude: latitude, elevation: elevation }.compact
    end

    def self.slugify_name(val)
      val.downcase.
        gsub(/(?:\s+and\s+|\s+-\s+|[^[:alpha:]\-]+)/, '-').
        gsub(/\A-*(.+?)-*\z/, '\1')
    end
  end

  class AdministrativeArea < Place
    field :population,        Integer
    field :official_name,     String
    def names ; super.tap{|arr| arr.insert(1, official_name) }.uniq.compact_blank ; end
  end

  class Country < AdministrativeArea
    field :country_al3id,   String, identifier: true,  doc: "ISO 3166 3-letter alphanumeric id ('usa', 'mex', etc). Must be lowercase."
    field :country_numid,   Integer, identifier: true, doc: "ISO 3166 numeric identifier ('usa' = 840)"
    field :tld_id,          String, doc: "TLD (top-level domain) identifier"
  end

  class CountryNameLookup
    include Gorillib::Model
    include Gorillib::Model::Indexable
    include Gorillib::Model::LoadFromTsv
    index_on :slug

    field :country_id, String
    field :country_al3id, String
    field :country_numid, Integer
    field :tld_id,        String
    field :geonames_id,   String
    field :name,          String
    field :slug,          String
    field :alt_name,      String

    def self.load(filename=nil)
      filename ||= :country_name_lookup
      @values = load_tsv(filename)
    end
  end
end
