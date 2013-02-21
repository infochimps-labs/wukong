require_relative '../../../common'
require 'geocoder'
require 'gorillib/model/serialization/tsv'
require 'redis'
require 'htmlentities'
require_relative './models'

Pathname.register_paths(
  ufo_rawd:   [:rawd, 'geo/ufo_sightings'],
  )
