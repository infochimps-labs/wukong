require_relative '../../../lib/wu/geo/models'
module Geo

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
