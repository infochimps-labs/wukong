require_relative './models'

class Airport
  class IdMapping
    include Gorillib::Model
    include Gorillib::Model::LoadFromCsv
    self.csv_options = { col_sep: "\t", num_fields: 4..6 }

    field :icao,         String, doc: "ICAO code (4-letter). For airports in the continental US that have an ICAO number, the ICAO number is their FAA identifier preceded by 'K'. Airports in Hawaii, Alaska and US posessions are prefixed with 'P', 'N', or 'T' and do not follow that pattern."
    field :iata,         String, doc: "IATA code (3-letter)"
    field :faa,          String, doc: "FAA code. This is often, but not always, the same as the IATA code."
    field :name,         String, doc: "Airport name"
    field :location,     String, doc: "Location of the airport"
    field :notes,        String, doc: "Advisory notes"

    ID_MAPPINGS  = { icao: {}, iata: {}, faa: {} }
      # Hash.new{|hsh,key| hsh[key] = Hash.new } # unless defined?(ID_MAPPINGS)

    # def adopt_field(that, attr)
    #   this_val = self.read_attribute(attr)
    #   that_val = that.read_attribute(attr)
    #   if name =~ /Bogus|Austin/i
    #     puts [attr, this_val, that_val, attribute_set?(attr), that.attribute_set?(attr), to_tsv, that.to_tsv].join("\t")
    #   end
    #   if    this_val && that_val
    #     if (this_val != that_val) then warn [attr, this_val, that_val, name].join("\t") ; end
    #   elsif that_val
    #     write_attribute(that_val)
    #   end
    # end

    def to_s
      attributes.values[0..2].join("\t")
    end

    def disagreements(that)
      errors = {}
      [:icao, :iata, :faa ].each do |attr|
        this_val = self.read_attribute(attr) or next
        that_val = that.read_attribute(attr) or next
        next if that_val == '.' || that_val == '_'
        errors[attr] = [this_val, that_val] if this_val != that_val
      end
      errors
    end

    # . icao _ iata

    def self.load(dirname)
      load_csv(File.join(dirname, 'wikipedia_icao.tsv')) do |id_mapping|
        [:icao, :iata, :faa ].each do |attr|
          val = id_mapping.read_attribute(attr) or next
          next if (val == '.') || (val == '_')
          if that = ID_MAPPINGS[attr][val]
            lint = that.disagreements(id_mapping)
            puts [attr, val, "%-25s" % lint.inspect, id_mapping, that, "%-60s" % id_mapping.name, "%-25s" % that.name].join("\t") if lint.present?
          else
            ID_MAPPINGS[attr][val] = id_mapping
          end
        end
        # [:icao, :iata, :faa ].each do |attr|
        #   val = id_mapping.read_attribute(attr)
        #   ID_MAPPINGS[attr][val] = id_mapping
        # end
      end
      load_csv(File.join(dirname, 'wikipedia_iata.tsv')) do |id_mapping|
        # if not ID_MAPPINGS[:icao].has_key?(id_mapping.icao)
        #   puts [:badicao, "%-25s" % "", id_mapping, " "*24, "%-60s" % id_mapping.name].join("\t")
        # end
        [:icao, :iata, :faa ].each do |attr|
          val = id_mapping.read_attribute(attr) or next
          next if (val == '.') || (val == '_')
          if that = ID_MAPPINGS[attr][val]
            lint = that.disagreements(id_mapping)
            puts [attr, val, "%-25s" % lint.inspect, id_mapping, that, "%-60s" % id_mapping.name, "%-25s" % that.name].join("\t") if lint.present?
          else
            ID_MAPPINGS[attr][val] = id_mapping
          end
        end
      end

    end

  end
end
