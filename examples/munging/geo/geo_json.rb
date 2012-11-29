# -*- coding: utf-8 -*-
module Wukong
  module Data
    class GeoJson           ; include Gorillib::Model ; end
    class GeoJson::Geometry ; include Gorillib::Model ; end

    class GeoJson
      include Gorillib::Model::LoadFromJson
      include Gorillib::Model::Indexable
      field :type,       String
      field :id,         String
      field :geometry,   GeoJson::Geometry
      field :properties, GenericModel

      def self.load(*args)
        load_json(*args) do |val|
          p val.properties
          p val.properties.to_place
        end
      end

    end

    class GeoJson::Geometry
      field :type,        String
      field :coordinates, Array

      def point?
        type == 'Point'
      end

      def longitude
        return nil if coordinates.blank?
        raise "Longitude only available for Point objects" unless point?
        coordinates[0]
      end
      def latitude
        return nil if coordinates.blank?
        raise "Latitude only available for Point objects" unless point?
        coordinates[1]
      end
    end

    class GeonamesGeoJson < GeoJson
      def receive_properties(hsh)
        if hsh.respond_to?(:merge)
          super(hsh.merge(geo_json_id: id, longitude: geometry.longitude, latitude: geometry.latitude))
        else
          super
        end
      end
    end
  end
end
