require 'gorillib/numeric/clamp'

module Wu
  module Geo
    #
    # Model mixins: uses the actual location fields (eg longitude/latitude) and provides the rest (tile coordinates / quadkey / bounding box)
    #
    module Geolocated

      #
      # using the longitude/latitude field of your model to provides the rest:
      # tile coordinates, quadkey and bounding box.
      #
      module ByCoordinates
        extend Gorillib::Concern
        # @return [Integer] quadkey id (the string of 0/1/2/3 quadtile indices; see Wu::Geo::Geolocation)
        def quadkey(zl)    ; Wu::Geo::Geolocation.tile_xy_zl_to_quadkey(  tile_x(zl), tile_y(zl), zl) ; end
        # @return [Integer] packed quadkey (the integer formed by interleaving the bits of tile_x with tile_y; see Wu::Geo::Geolocation)
        def packed_qk      ; Wu::Geo::Geolocation.tile_xy_zl_to_packed_qk(tile_x(zl), tile_y(zl), zl) ; end
        # @return [Float] x index of the tile this object lies on at given zoom level
        def tile_xf(zl)    ; Wu::Geo::Geolocation.lng_zl_to_tile_xf(longitude, zl)  ; end
        # @return [Float] y index of the tile this object lies on at given zoom level
        def tile_yf(zl)    ; Wu::Geo::Geolocation.lat_zl_to_tile_yf(latitude,  zl)  ; end
        # @return [Integer] x index of the tile this object lies on at given zoom level
        def tile_x(zl)     ; tile_xf(zl).floor  ; end
        # @return [Integer] y index of the tile this object lies on at given zoom level
        def tile_y(zl)     ; tile_yf(zl).floor  ; end
        # @return [Float] tile coordinates `(x,y)` for this object at given zoom level
        def tile_xy(zl)    ; [tile_x(xl), tile_y(zl)] ; end
        # @returns [Array<Numeric, Numeric>] a `[longitude, latitude]` pair representing object as a point.
        def lng_lat        ; [longitude, latitude] ; end
        # @returns [left, btm, right, top]
        def bbox_for_radius(radius) ; Wu::Geo::Geolocation.lng_lat_rad_to_bbox(longitude, latitude, radius) ; end
      end
    end
  end
end
