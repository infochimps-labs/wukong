module Wukong
  module Geo
    class Quadtile
      include Gorillib::Model
      #
      field :tile_x, Integer, position: 0, doc: "Tile X index, an integer between 0 and 2^zoom_level - 1"
      field :tile_y, Integer, position: 1, doc: "Tile Y index, an integer between 0 and 2^zoom_level - 1"
      field :zl,     Integer, position: 2, doc: "Zoom level of tile to fetch. 0 is the world; 16 is about a kilometer."
      field :slug,   String,  default: 'tile', doc: "Name, prefixed on saved tiles"

      def quadkey   ; Wukong::Geolocated.tile_xy_zl_to_quadkey(  tile_x, tile_y, zl) ; end
      def packed_qk ; Wukong::Geolocated.tile_xy_zl_to_packed_qk(tile_x, tile_y, zl) ; end

      # Base of URL for map tile server; anything X/Y/Z.png-addressable works,
      # eg `http://b.tile.openstreetmap.org`. Defaults to 'http://b.tile.stamen.com/toner-lite'`.
      class_attribute :tileserver_url_base
      self.tileserver_url_base = 'http://a.tile.stamen.com/toner-lite'

      def self.from_whatever(hsh)
        zl = hsh[:zl] ? hsh[:zl].to_i : nil
        case
        when hsh[:tile_x].present? && hsh[:tile_y].present? && zl.present?
          tile_x, tile_y = [hsh[:tile_x], hsh[:tile_y]]
        when hsh[:longitude].present? && hsh[:latitude].present? && zl.present?
          tile_x, tile_y = Wukong::Geolocated.lng_lat_zl_to_tile_xy(hsh[:longitude], hsh[:latitude], zl)
        when hsh[:quadkey].present?
          quadkey = hsh[:quadkey]
          quadkey = quadkey[0..zl] if zl.to_i > 0
          tile_x, tile_y, zl = Wukong::Geolocated.quadkey_to_tile_xy_zl(quadkey)
        else
          raise ArgumentError, "You must supply keys for either `:longitude`, `:latitude` and `:zl`; `:tile_x`, `:tile_y` and `:zl`; or `:quadkey`: #{hsh.inspect}"
        end
        return new(tile_x, tile_y, zl, hsh.to_hash)
      end

      def self.tileserver_conn
        @tileserver_conn = Faraday.new(:url => tileserver_url_base)
      end

      def tile_url
        [tileserver_url_base, zl, tile_x, tile_y].join('/') << ".png"
      end

      # A
      #
      # @example
      #   qt = Quadtile.from_whatever(longitude: -97.759003, latitude: 30.273884, zl: 15)
      #   qt.slug  # tile-15-64587
      #
      #
      # @returns [String]
      def basename(options={})
        options = { sep: '-', ext: 'png'}
        sep = options[:sep]
        # "%s%s%02d%s%04d%s%04d.%s" % [slug, sep, zl, sep, tile_x, sep, tile_y, options[:ext]]
        "%s/%02d/%s%s%s.%s" % [slug, zl, slug, sep, quadkey, options[:ext]]
      end

      # Fetch the contents of a map tile from a tileserver
      #
      # You are responsible for requiring the faraday library and its adapter
      #
      def fetch
        self.class.tileserver_conn.get(tile_url)
      end

    end
  end
end
