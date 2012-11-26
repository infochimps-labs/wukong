#!/usr/bin/env ruby

require 'faraday'
require 'gorillib/pathname/utils'
#
require_relative '../rake_helper'
require_relative '../geo'

Pathname.register_paths(
  images:     [:root, 'images', 'map_grid_cells'],
  )

Settings.use :commandline
Settings.define :server,     default: 'http://a.tile.stamen.com/toner-lite', description: "Map tile server; anything X/Y/Z.png-addressable works, eg http://b.tile.openstreetmap.org"
Settings.define :clobber,    default: true, type: :boolean, description: "true to overwrite files (the default)"

Settings.define :slug,       default: 'tile', description: "A name to prefix on the file"

Settings.define :zl,                        description: "Zoom level of tile to fetch. An integer between 0 (world) and 16 or so"
Settings.define :tile_x,     type: Integer, description: "Tile X index, an integer between 0 and 2^zoom_level - 1"
Settings.define :tile_y,     type: Integer, description: "Tile Y index, an integer between 0 and 2^zoom_level - 1"
Settings.define :longitude,  type: Float,   description: "Longitude (X) of a point on the tile in decimal degrees"
Settings.define :latitude,   type: Float,   description: "Latitude (Y) of a point on the tile in decimal degrees"
Settings.define :quadkey,                   description: "Quadkey of tile, eg 002313012."

Settings.resolve!

def fetch_tile(tile_info)
  tile = Wukong::Geo::Quadtile.from_whatever(tile_info)

  Pathname.of(:images, tile.basename(Settings.slug)).if_missing(force: Settings.clobber) do |output_file|
    Log.info "Writing to file #{output_file.path} from #{tile.tile_url}"
    output_file << tile.fetch.body
  end
end

tile_info = Settings.to_hash

MAX_TILES_TO_FETCH = 1e4 unless defined?(MAX_TILES_TO_FETCH)
# MAX_TILES_TO_FETCH = 18 unless defined?(MAX_TILES_TO_FETCH)

def quadkey_range(quadkey, zl, zl_max, &block)
  return if zl > zl_max
  p [quadkey, zl, zl_max]
  #
  if quadkey.length >= zl
    yield quadkey[0 .. zl]
    quadkey_range(quadkey, zl+1, zl_max, &block)
  else
    n_tiles = 4 ** (zl_max - quadkey.length)
    if (n_tiles > MAX_TILES_TO_FETCH) then raise "Too many sub-tiles: #{quadkey} at zl #{zl}..#{zl_max} would create #{n_tiles} tiles; limit is #{MAX_TILES_TO_FETCH}" ; end
    #
    (0..3).each do |quad|
      quadkey_range("#{quadkey}#{quad}", zl, zl_max, &block)
    end
  end
end

# Guess the zoom level from quadkey if missing
Settings.zl ||= Settings.quadkey.length.to_s if Settings.quadkey.present?
# and then extract the range if any
zl_min, zl_max = Settings.zl.split('-', 2)
zl_min = zl_min.to_i
zl_max = zl_max ? zl_max.to_i : zl_min

if Settings.quadkey.present?
  Settings.quadkey.gsub!(/_/, '')

  quadkey_range(Settings.quadkey, zl_min, zl_max) do |quadkey|
    fetch_tile(tile_info.merge(quadkey: quadkey, zl: quadkey.length))
  end

else
  (zl_min.to_i .. zl_max.to_i).each do |zl|
    fetch_tile(tile_info.merge(zl: zl))
  end
end
