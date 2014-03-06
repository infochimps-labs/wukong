require_relative './models'
require 'gorillib/model/reconcilable'

class Airport
  include Gorillib::Model::Reconcilable
  attr_accessor :_origin # source of the record

  def conflicting_attribute!(attr, this_val, that_val)
    case attr
    when :name, :city, :airport_ofid then return :pass
    when :latitude, :longitude       then return true if (this_val - that_val).abs < 3
    when :altitude                   then return true if (this_val - that_val).abs < 5
    end
    super
  end

  def ids
    [:icao, :iata, :faa].hashify{|attr| public_send(attr) }.compact
  end
end

#
# Loads the Airport identifier tables scraped from Wikipedia
#
class RawAirportIdentifier < Airport
  include RawAirport
  include Gorillib::Model::LoadFromTsv

  def self.from_tuple(icao, iata, faa, name, city=nil, *_)
    self.new({icao: icao, iata: iata, faa: faa, name: name, city: city}.compact_blank)
  end

  def self.load_airports(filename, &block)
    load_tsv(filename, num_fields: 4..6, &block)
  end
end

class Airport
  #
  # Reconciler for Airports
  #
  # For each airport in turn across openflights, dataexpo and the two scraped
  # identifier sets,
  # 
  #
  class IdReconciler
    include Gorillib::Model
    include Gorillib::Model::LoadFromCsv
    include Gorillib::Model::Reconcilable
    self.csv_options = { col_sep: "\t", num_fields: 3..6 }

    # Map the reconcilers to each ID they have anything to say about
    ID_MAP = { icao: {}, iata: {}, faa: {} }
    
    field :opinions, Array, default: Array.new, doc: "every record having an id in common with the other records in this field"

    def ids
      opinions.flat_map{|op| op.ids.to_a }.uniq.compact
    end

    def self.load_all
      Log.info "Loading all Airports and reconciling"
      @airports = Array.new
      RawDataexpoAirport  .load_airports(:dataexpo_raw_airports   ){|airport| register(:dataexpo, airport) }
      RawOpenflightAirport.load_airports(:openflights_raw_airports){|airport| register(:openflights, airport) }
      RawAirportIdentifier.load_airports(:wikipedia_icao          ){|airport| register(:wp_icao, airport) }
      RawAirportIdentifier.load_airports(:wikipedia_iata          ){|airport| register(:wp_iata, airport) }
      RawAirportIdentifier.load_airports(:wikipedia_us_abroad     ){|airport| register(:wp_us_abroad, airport) }

      recs = ID_MAP.map{|attr, hsh| hsh.sort.map(&:last) }.flatten.uniq
      recs.each do |rec|
        consensus = rec.reconcile
        # lint = consensus.lint
        # puts "%-79s\t%s" % [lint, consensus.to_s[0..100]] if lint.present?
        @airports << consensus
      end
    end

    def self.airports
      @airports
    end

    def self.exemplars
      Airport::EXEMPLARS.map do |iata|
        ID_MAP[:iata][iata].reconcile
      end
    end

    def reconcile
      consensus = Airport.new
      clean = opinions.all?{|op| consensus.adopt(op) }
      # puts "\t#{consensus.inspect}"
      puts "confl\t#{self.inspect}" if not clean
      consensus
    end

    def adopt_opinions(vals, _)
      self.opinions = vals + self.opinions
      self.opinions.uniq!
    end

    # * find all existing reconcilers that share an ID with that record
    # * unify them into one reconciler
    # * store it back under all the IDs
    #
    # Suppose our dataset has 3 identifiers, which look like
    #
    #     a    S
    #          S    88
    #     a    Z
    #     b
    #          Q
    #     b    Q    77
    #
    # We will wind up with these two reconcilers:
    #
    #     <a S 88 opinions: [a,S, ],[S, ,88],[a,Z,  ]>
    #     <b Q 77 opinions: [b, , ],[ ,Q,  ],[b,Q,77]>
    #
    def self.register(origin, obj)
      obj._origin = origin
      # get the existing reconcilers
      existing   = obj.ids.map{|attr, id| ID_MAP[attr][id] }.compact.uniq
      # push the new object in, and pull the most senior one out
      existing.unshift(self.new(opinions: [obj]))
      reconciler = existing.shift
      # unite them into the reconciler
      existing.each{|that| reconciler.adopt(that) }
      # save the reconciler under each of the ids.
      reconciler.ids.each{|attr, id| ID_MAP[attr][id] = reconciler }
    end

    def inspect
      str = "#<#{self.class.name} #{ids}"
      opinions.each do |op|
        str << "\n\t  #{op._origin}\t#{op}"
      end
      str << ">"
    end
  end

end
