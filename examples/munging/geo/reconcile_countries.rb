require 'gorillib/model/reconcilable'
# require_relative('./geo_models')
# require_relative('./geo_json')

module Geo

  Place.class_eval do
    include Gorillib::Model::Reconcilable

    def adopt_alternate_names(that_val, _)
      return true if that_val.blank?
      names = "#{alternate_names}|#{that_val}".split("|")
      names.uniq!
      names.delete(name)
      write_attribute :alternate_names, names.compact_blank.join("|")
      true
    end

    def conflicting_attribute!(attr, this_val, that_val)
      case attr
      when :name, :official_name then return :pass
      end
      super
    end

  end

  Country.class_eval do
    index_on :country_id
    field :iso_3166_active, :boolean
  end


  class FullIso3166
    include Gorillib::Model
    include Gorillib::Model::Reconcilable
    include Gorillib::Model::LoadFromTsv
    self.tsv_options = self.tsv_options.merge(num_fields: 6..8, pop_headers: true)

    field :country_id,      String
    field :tld_id,          String
    field :iso_3166_3,      String
    field :name,            String
    field :code_status,     String
    field :iso_3166_active, :boolean, blankish: ['N', false, nil, '']
    field :year_granted,    String
    field :notes,           String

    def active?
      iso_3166_active == "Y"
    end

    def to_place
      Geo::Country.receive({
          country_id:      country_id,
          name:            name,
          tld_id:          tld_id,
          iso_3166_active: iso_3166_active,
        })
    end
  end

end

# cd    Congo (Kinshasa)
# um    Baker Island
# um    Howland Island
# um    Jarvis Island
# um    Johnston Atoll
# um    Kingman Reef
# um    Midway Islands
# um    Navassa Island
# um    Palmyra Atoll
# um    Wake Island
# mi    Midway Islands
# na    Netherlands Antilles
# gs    South Georgia and the Islands
# sj    Svalbard
# wk    Wake Island
# ps    West Bank
# ps    West Bank and the Gaza Strip
# ps    Gaza Strip

class CountryReconciler

  def self.load_reconciled_countries

    Geo::FullIso3166.load_tsv([:geo_data, 'iso_codes/full_iso_3166.tsv']) do |raw_country|
      Geo::Country.values << raw_country.to_place
    end

    Wukong::Data::CountryCode.load
    Wukong::Data::CountryCode.values.each do |raw_country|
      iso_country = raw_country.to_place
      country = Geo::Country.for_country_id(iso_country.country_id){ Geo::Country.new }
      country.adopt(iso_country)
    end

    Wukong::Data::GeonamesGeoJson.load_json(:geonames_countries) do |raw_feature|
      gn_country = raw_feature.properties.to_place
      country = Geo::Country.for_country_id(gn_country.country_id){ Geo::Country.new }
      country.adopt(gn_country)
    end

    Geo::Country.values.sort_by!(&:country_id)
  end
end



# {
#   :xx => { :name => 'Iran' },
#   :xx => 'Tanzania, United Republic',
#   :xx => 'Palestinian Territory, Occupied',
#   :xx =>
# }
# :kp => "North Korea"  Korea, Democratic People's Republic
# :kr => "South Korea"  Korea, Republic of
# :bn => "Brunei"
# :bq => "Caribbean Netherlands"
# Lao People's Democratic Republic
#
# :va Holy See (Vatican City State)
# :vi Virgin Islands, U.S.
