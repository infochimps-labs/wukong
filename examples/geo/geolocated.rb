require 'gorillib/numeric/clamp'

Numeric.class_eval do
  def to_radians() self.to_f * Math::PI / 180.0 ; end
  def to_degrees() self.to_f * 180.0 / Math::PI ; end
end

module Wukong
  #
  # reference: [Bing Maps Tile System](http://msdn.microsoft.com/en-us/library/bb259689.aspx)
  #
  module Geolocated
    module_function # call methods as eg Wukong::Geolocated.tile_xy_to_quadkey or, if included in class, on self as private methods

    # field :longitude,  type: Float,   description: "Longitude (X) of a point, in decimal degrees"
    # field :latitude,   type: Float,   description: "Latitude (Y) of a point, in decimal degrees"
    # field :zoom_level, type: Integer, description: "Zoom level of tile to fetch. An integer between 0 (world) and 16 or so"
    # field :quadkey,    type: String,  description: "Quadkey of tile, eg 002313012"
    # field :tile_x,     type: Integer, description: "Tile X index, an integer between 0 and 2^zoom_level - 1"
    # field :tile_y,     type: Integer, description: "Tile Y index, an integer between 0 and 2^zoom_level - 1"

    module ByCoordinates
      extend Gorillib::Concern

      # The quadkey is a string of 2-bit tile selectors for a quadtile
      #
      # @example
      #   infochimps_hq = Geo::Place.receive("Infochimps HQ", -97.759003, 30.273884)
      #   infochimps_hq.quadkey(8) # => "02313012"
      #
      # Interesting quadkey properties:
      #
      # * The quadkey length is its zoom level
      #
      # * To zoom out (lower zoom level, larger quadtile), just truncate the
      #   quadkey: austin at ZL=8 has quadkey "02313012"; at ZL=3, "023"
      #
      # * Nearby points typically have "nearby" quadkeys: up to the smallest
      #   tile that contains both, their quadkeys will have a common prefix.
      #   If you sort your records by quadkey,
      #   - Nearby points are nearby-ish on disk. (hello, HBase/Cassandra
      #     database owners!) This allows efficient lookup and caching of
      #     "popular" regions or repeated queries in an area.
      #   - the tiles covering a region can be covered by a limited, enumerable
      #     set of range scans. For map-reduce programmers, this leads to very
      #     efficient reducers
      #
      # * The quadkey is the bit-interleaved combination of its tile ids:
      #
      #       tile_x      58  binary  0  0  1  1  1  0  1  0
      #       tile_y      105 binary 0  1  1  0  1  0  0  1
      #       interleaved     binary 00 10 11 01 11 00 01 10
      #       quadkey                 0  2  3  1  3  0  1  2 #  "02313012"
      #
      def quadkey(zl)    ; Wukong::Geolocated.tile_xy_zl_to_quadkey(  tile_x(zl), tile_y(zl), zl) ; end

      # the packed quadkey is the integer formed by interleaving the bits of tile_x with tile_y:
      #
      #       tile_x      58  binary  0  0  1  1  1  0  1  0
      #       tile_y      105 binary 0  1  1  0  1  0  0  1
      #       interleaved     binary 00 10 11 01 11 00 01 10
      #       quadkey                 0  2  3  1  3  0  1  2 #  "02313012"
      #
      # (see `quadkey` for more.)
      #
      # At zoom level 15, the packed quadkey is a 30-bit unsigned integer --
      # meaning you can store it in a pig `int`; for languages with an `unsigned
      # int` type, you can go to zoom level 16 before you have to use a
      # less-efficient type. Zoom level 15 has a resolution of about one tile
      # per kilometer (about 1.25 km/tile near the equator; 0.75 km/tile at
      # London's latitude). It takes 1 billion tiles to tile the world at that
      # scale. Ruby's integer type goes up to 60 bits, enough for any practical
      # zoom level.
      #
      def packed_qk      ; Wukong::Geolocated.tile_xy_zl_to_packed_qk(tile_x(zl), tile_y(zl), zl) ; end

      # @return [Float] x index of the tile this object lies on at given zoom level
      def tile_xf(zl)    ; Wukong::Geolocated.lng_zl_to_tile_xf(longitude, zl)  ; end
      # @return [Float] y index of the tile this object lies on at given zoom level
      def tile_yf(zl)    ; Wukong::Geolocated.lat_zl_to_tile_yf(latitude,  zl)  ; end
      # @return [Integer] x index of the tile this object lies on at given zoom level
      def tile_x(zl)     ; tile_xf(zl).floor  ; end
      # @return [Integer] y index of the tile this object lies on at given zoom level
      def tile_y(zl)     ; tile_yf(zl).floor  ; end

      # @return [Float] tile coordinates `(x,y)` for this object at given zoom level
      def tile_xy(zl)    ; [tile_x(xl), tile_y(zl)] ; end

      # @returns [Array<Numeric, Numeric>] a `[longitude, latitude]` pair representing object as a point.
      def lng_lat        ; [longitude, latitude] ; end

      # @returns [left, btm, right, top]
      def bbox_for_radius(radius) ; Wukong::Geolocated.lng_lat_rad_to_bbox(longitude, latitude, radius) ; end
    end

    EARTH_RADIUS      =  6371000 # meters
    MIN_LONGITUDE     = -180
    MAX_LONGITUDE     =  180
    MIN_LATITUDE      = -85.05112878
    MAX_LATITUDE      =  85.05112878
    ALLOWED_LONGITUDE = (MIN_LONGITUDE..MAX_LONGITUDE)
    ALLOWED_LATITUDE  = (MIN_LATITUDE..MAX_LATITUDE)
    TILE_PIXEL_SIZE   =  256

    # Width or height in number of tiles
    def map_tile_size(zl)
      1 << zl
    end

    #
    # Tile coordinates
    #

    # Convert longitude in degrees to _floating-point_ tile x,y coordinates at given zoom level
    def lng_zl_to_tile_xf(longitude, zl)
      raise ArgumentError, "longitude must be within bounds ((#{longitude}) vs #{ALLOWED_LONGITUDE})" unless (ALLOWED_LONGITUDE.include?(longitude))
      xx = (longitude.to_f + 180.0) / 360.0
      (map_tile_size(zl) * xx)
    end

    # Convert latitude in degrees to _floating-point_ tile x,y coordinates at given zoom level
    def lat_zl_to_tile_yf(latitude, zl)
      raise ArgumentError, "latitude must be within bounds ((#{latitude}) vs #{ALLOWED_LATITUDE})" unless (ALLOWED_LATITUDE.include?(latitude))
      sin_lat = Math.sin(latitude.to_radians)
      yy = Math.log((1 + sin_lat) / (1 - sin_lat)) / (4 * Math::PI)
      (map_tile_size(zl) * (0.5 - yy))
    end

    # Convert latitude in degrees to integer tile x,y coordinates at given zoom level
    def lng_lat_zl_to_tile_xy(longitude, latitude, zl)
      [lng_zl_to_tile_xf(longitude, zl).floor, lat_zl_to_tile_yf(latitude, zl).floor]
    end

    # Convert from tile_x, tile_y, zoom level to longitude and latitude in
    # degrees (slight loss of precision).
    #
    # Tile coordinates may be floats or integer; they must lie within map range.
    def tile_xy_zl_to_lng_lat(tile_x, tile_y, zl)
      tile_size = map_tile_size(zl)
      raise ArgumentError, "tile index must be within bounds ((#{tile_x},#{tile_y}) vs #{tile_size})" unless ((0..(tile_size-1)).include?(tile_x)) && ((0..(tile_size-1)).include?(tile_x))
      xx =       (tile_x.to_f / tile_size)
      yy = 0.5 - (tile_y.to_f / tile_size)
      lng = 360.0 * xx - 180.0
      lat = 90 - 360 * Math.atan(Math.exp(-yy * 2 * Math::PI)) / Math::PI
      [lng, lat]
    end

    #
    # Quadkey coordinates
    #

    # converts from even/odd state of tile x and tile y to quadkey. NOTE: bit order means y, x
    BIT_TO_QUADKEY = { [false, false] => "0", [false, true] => "1", [true, false] => "2", [true, true] => "3", }
    # converts from quadkey char to bits. NOTE: bit order means y, x
    QUADKEY_TO_BIT = { "0" => [0,0], "1" => [0,1], "2" => [1,0], "3" => [1,1]}

    # Convert from tile x,y into a quadkey at a specified zoom level
    def tile_xy_zl_to_quadkey(tile_x, tile_y, zl)
      quadkey_chars = []
      tx = tile_x.to_i
      ty = tile_y.to_i
      zl.times do
        quadkey_chars.push BIT_TO_QUADKEY[[ty.odd?, tx.odd?]] # bit order y,x
        tx >>= 1 ; ty >>= 1
      end
      quadkey_chars.join.reverse
    end

    # Convert a quadkey into tile x,y coordinates and level
    def quadkey_to_tile_xy_zl(quadkey)
      raise ArgumentError, "Quadkey must contain only the characters 0, 1, 2 or 3: #{quadkey}!" unless quadkey =~ /\A[0-3]*\z/
      zl = quadkey.to_s.length
      tx = 0 ; ty = 0
      quadkey.chars.each do |char|
        ybit, xbit = QUADKEY_TO_BIT[char] # bit order y, x
        tx = (tx << 1) + xbit
        ty = (ty << 1) + ybit
      end
      [tx, ty, zl]
    end

    # Convert from tile x,y into a packed quadkey at a specified zoom level
    def tile_xy_zl_to_packed_qk(tile_x, tile_y, zl)
      # don't optimize unless you're sure your way is faster; string ops are
      # faster than you think and loops are slower than you think
      quadkey_str = tile_xy_zl_to_quadkey(tile_x, tile_y, zl)
      quadkey_str.to_i(4)
    end

    # Convert a packed quadkey (integer) into tile x,y coordinates and level
    def packed_qk_zl_to_tile_xy(packed_qk, zl=16)
      # don't "optimize" this without testing... string operations are faster than you think in ruby
      raise ArgumentError, "Quadkey must be an integer in range of the zoom level: #{packed_qk}, #{zl}" unless packed_qk.is_a?(Fixnum) && (packed_qk < 2 ** (zl*2))
      quadkey_rhs = packed_qk.to_s(4)
      quadkey     = ("0" * (zl - quadkey_rhs.length)) << quadkey_rhs
      quadkey_to_tile_xy_zl(quadkey)
    end

    # Convert a lat/lng and zoom level into a quadkey
    def lng_lat_zl_to_quadkey(longitude, latitude, zl)
      tile_x, tile_y = lng_lat_zl_to_tile_xy(longitude, latitude, zl)
      tile_xy_zl_to_quadkey(tile_x, tile_y, zl)
    end

    #
    # Bounding box coordinates
    #

    # Convert a quadkey into a bounding box using adjacent tile
    def quadkey_to_bbox(quadkey)
      tile_x, tile_y, zl = quadkey_to_tile_xy_zl(quadkey)
      # bottom right of me is top left of my southeast neighbor
      left,  top = tile_xy_zl_to_lng_lat(tile_x,     tile_y,     zl)
      right, btm = tile_xy_zl_to_lng_lat(tile_x + 1, tile_y + 1, zl)
      [left, btm, right, top]
    end

    # Retuns the smallest quadkey containing both of corners of the given bounding box
    def quadkey_containing_bbox(left, btm, right, top)
      qk_tl = lng_lat_zl_to_quadkey(left,  top, 23)
      qk_2  = lng_lat_zl_to_quadkey(right, btm, 23)
      # the containing qk is the longest one that both agree on
      containing_key = ""
      qk_tl.chars.zip(qk_2.chars).each do |char_tl, char_2|
        break if char_tl != char_2
        containing_key << char_tl
      end
      containing_key
    end

    # Returns a bounding box containing the circle created by the lat/lng and radius
    def lng_lat_rad_to_bbox(longitude, latitude, radius)
      left, _    = point_east( longitude, latitude, -radius)
      _,     btm = point_north(longitude, latitude, -radius)
      right, _   = point_east( longitude, latitude,  radius)
      _,     top = point_north(longitude, latitude,  radius)
      [left, btm, right, top]
    end

    # Returns the centroid of a bounding box
    #
    # @param [Array<Float, Float>] left_btm  Longitude, Latitude of SW point
    # @param [Array<Float, Float>] right_top Longitude, Latitude of NE point
    #
    # @return [Array<Float, Float>] Longitude, Latitude of centroid
    def bbox_centroid(left_btm, right_top)
      haversine_midpoint(*left_btm, *right_top)
    end

    # Return the haversine distance in meters between two points
    def haversine_distance(left, btm, right, top)
      delta_lng = (right - left).abs.to_radians
      delta_lat = (top   - btm ).abs.to_radians
      btm_rad = btm.to_radians
      top_rad = top.to_radians

      aa = (Math.sin(delta_lat / 2.0))**2 + Math.cos(top_rad) * Math.cos(btm_rad) * (Math.sin(delta_lng / 2.0))**2
      cc = 2.0 * Math.atan2(Math.sqrt(aa), Math.sqrt(1.0 - aa))
      cc * EARTH_RADIUS
    end

    # Return the haversine midpoint in meters between two points
    def haversine_midpoint(left, btm, right, top)
      cos_btm   = Math.cos(btm.to_radians)
      cos_top   = Math.cos(top.to_radians)
      bearing_x = cos_btm * Math.cos((right - left).to_radians)
      bearing_y = cos_btm * Math.sin((right - left).to_radians)
      mid_lat   = Math.atan2(
        (Math.sin(top.to_radians) + Math.sin(btm.to_radians)),
        (Math.sqrt((cos_top + bearing_x)**2 + bearing_y**2)))
      mid_lng   = left.to_radians + Math.atan2(bearing_y, (cos_top + bearing_x))
      [mid_lng.to_degrees, mid_lat.to_degrees]
    end

    # From a given point, calculate the point directly north a specified distance
    def point_north(longitude, latitude, distance)
      north_lat = (latitude.to_radians + (distance.to_f / EARTH_RADIUS)).to_degrees
      [longitude, north_lat]
    end

    # From a given point, calculate the change in degrees directly east a given distance
    def point_east(longitude, latitude, distance)
      radius = EARTH_RADIUS * Math.sin(((Math::PI / 2.0) - latitude.to_radians.abs))
      east_lng = (longitude.to_radians + (distance.to_f / radius)).to_degrees
      [east_lng, latitude]
    end

    #
    # Pixel coordinates
    #
    # Use with a standard (256x256 pixel) grid-based tileserver
    #

    # Width or height of grid bitmap in pixels at given zoom level
    def map_pixel_size(zl)
      TILE_PIXEL_SIZE * map_tile_size(zl)
    end

    # Return pixel resolution in meters per pixel at a specified latitude and zoom level
    def pixel_resolution(latitude, zl)
      lat = latitude.clamp(MIN_LATITUDE, MAX_LATITUDE)
      Math.cos(lat.to_radians) * 2 * Math::PI * EARTH_RADIUS / map_pixel_size(zl).to_f
    end

    # Map scale at a specified latitude, zoom level, & screen resolution in dpi
    def map_scale_for_dpi(latitude, zl, screen_dpi)
      pixel_resolution(latitude, zl) * screen_dpi / 0.0254
    end

    # Convert from x,y pixel pair into tile x,y coordinates
    def pixel_xy_to_tile_xy(pixel_x, pixel_y)
      [pixel_x / TILE_PIXEL_SIZE, pixel_y / TILE_PIXEL_SIZE]
    end

    # Convert from x,y tile pair into pixel x,y coordinates (top left corner)
    def tile_xy_to_pixel_xy(tile_x, tile_y)
      [tile_x * TILE_PIXEL_SIZE, tile_y * TILE_PIXEL_SIZE]
    end

    def pixel_xy_zl_to_lng_lat(pixel_x, pixel_y, zl)
      tile_xy_zl_to_lng_lat(pixel_x.to_f / TILE_PIXEL_SIZE, pixel_y.to_f / TILE_PIXEL_SIZE, zl)
    end

    def lng_lat_zl_to_pixel_xy(lng, lat, zl)
      pixel_x = lng_zl_to_tile_xf(lng, zl)
      pixel_y = lat_zl_to_tile_yf(lat, zl)
      [(pixel_x * TILE_PIXEL_SIZE + 0.5).floor, (pixel_y * TILE_PIXEL_SIZE + 0.5).floor]
    end

  end
end
