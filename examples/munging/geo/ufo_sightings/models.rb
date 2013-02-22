require 'wu/geo/models'

class UfoSighting
  include Wu::Model
  field :sighted_at,   Time
  field :reported_at,  Time
  field :shape,        Symbol
  field :duration_str, String
  field :location_str, String
  field :place,        Wu::Geo::Place
  field :description,  String

  def shape_category
    case shape
    when :round, :egg, :oval, :sphere, :disk, :circle              then [:roundish ]
    when :triangle, :delta, :rectangle, :diamond, :cross, :hexagon then [:angular  ]
    when :cone, :teardrop, :cylinder, :cigar                       then [:coneish  ]
    when :chevron, :formation                                      then [:multiple ]
    when :flare, :flash, :changing, :fireball, :light, :changed    then [:ethereal ]
    when :unknown, :other                                          then [:unknown  ]
    when :pyramid                                                  then [:coneish,  :angular]
    when :crescent                                                 then [:roundish, :angular]
    when :dome                                                     then [:coneish, :roundish]
    else
      :unknown
    end
    SHAPE_CATEGORIES[shape] || :unknown
  end
end

class RawUfoSighting
  include Gorillib::Model
  include Gorillib::Model::LoadFromTsv

  field :sighted_at,   Time
  field :reported_at,  Time
  field :location_str, String
  field :shape,        String
  field :raw_duration, String
  field :description,  String
end

class RawGeocoderPlace
  include Gorillib::Model

  field :name,          String
  field :place_class,   String
  field :place_type,    String
  field :place_id,      String
  #
  field :coordinates,   String
  field :latitude,      Float
  field :longitude,     Float
  field :bbox,          Whatever
  field :polygonpoints, Whatever
  #
  field :address,       String
  field :country,       String
  field :country_code,  String
  field :state,         String
  field :state_code,    String
  field :county,        String
  field :city,          String
  field :postal_code,   String
  field :house_number,  String
  field :timezone,      String
  #
  field :osm_id,        Integer
  field :osm_type,      String
  field :poi,           String
  field :importance,    Float
  field :confidence,    String

  def bbox_str
    return unless bbox.present?
    bbox.map{|cc| "%7.2f" % cc }.join(',')
  end

  def to_wire
    super.values_at(:country, :state, :county, :city, :confidence) + [bbox_str]
  end

  def self.receive_result(obj)
    hsh = self.field_names.hashify{|fld| obj.send(fld) if obj.respond_to?(fld) }
    receive(hsh)
  end
end

class RawNominatimAddress
  include Gorillib::Model
  include Gorillib::Model::LoadFromTsv

  field :city,          String
  field :county,        String
  field :state,         String
  field :country,       String
  field :country_code,  String
end

class RawNominatimPlace
  include Gorillib::Model
  include Gorillib::Model::LoadFromTsv

  field :place_id,      Integer
  field :licence,       String
  field :osm_type,      String
  field :osm_id,        Integer
  field :boundingbox,   String
  field :lat,           Float
  field :lon,           Float
  field :display_name,  String
  field :place_class,   String
  field :type,          String
  field :importance,    Float
  field :icon,          String

  def receive!(hsh)
    hsh[:place_class] ||= hsh.delete(:class)
    super(hsh)
  end
end
