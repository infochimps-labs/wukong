class Airport

  # [Hash] all options passed to the field not recognized by one of its own current fields
  attr_reader :_extra_attributes

    # # Airports whose IATA and FAA codes differ; all are in the US, so their ICAO is "K"+the FAA id
    # FAA_ICAO_FIXUP = {
    #   "GRM" => "CKC", "CLD" => "CRQ", "SDX" => "SEZ", "AZA" => "IWA", "SCE" => "UNV", "BLD" => "BVU",
    #   "LKE" => "W55", "HSH" => "HND", "BKG" => "BBG", "UST" => "SGJ", "LYU" => "ELO", "WFK" => "FVE",
    #   "FRD" => "FHR", "ESD" => "ORS", "RKH" => "UZA", "NZC" => "VQQ", "SCF" => "SDL", "JCI" => "IXD",
    #   "AVW" => "AVQ", "UTM" => "UTA", "ONP" => "NOP", }
    #
    # [:iata, :icao, :latitude, :longitude, :country, :city, :name].each do |attr|
    #   define_method("of_#{attr}"){ @_extra_attributes[:"of_#{attr}"] }
    #   define_method("de_#{attr}"){ @_extra_attributes[:"de_#{attr}"] }
    # end
    #
    # def lint_differences
    #   errors = {}
    #   return errors unless de_name.present? && of_name.present?
    #   [
    #     [:iata, of_iata, de_iata], [:icao, of_icao, de_icao], [:country, of_country, de_country],
    #     [:city, of_city, de_city],
    #     [:name, of_name, de_name],
    #   ].each{|attr, of, de| next unless of && de ; errors[attr] = [of, de] if of != de }
    #
    #   if (of_latitude && of_longitude && de_latitude && de_longitude)
    #     lat_diff = (of_latitude  - de_latitude ).abs
    #     lng_diff = (of_longitude - de_longitude).abs
    #     unless (lat_diff < 0.015) && (lng_diff < 0.015)
    #       msg = [of_latitude, de_latitude, of_longitude, de_longitude, lat_diff, lng_diff].map{|val| "%9.4f" % val }.join(" ")
    #       errors["distance"] = ([msg, of_city, de_city, of_name, de_name])
    #     end
    #   end
    #
    #   errors
    # end
    #
    # AIRPORTS      = Hash.new # unless defined?(AIRPORTS)
    # def self.load(of_filename, de_filename)
    #   RawOpenflightAirport.load_csv(of_filename) do |raw_airport|
    #     airport = raw_airport.to_airport
    #     AIRPORTS[airport.iata_icao] = airport
    #   end
    #   RawDataexpoAirport.load_csv(de_filename) do |raw_airport|
    #     airport = (AIRPORTS[raw_airport.iata_icao] ||= self.new)
    #     if airport.de_name
    #       warn "duplicate data for #{[iata, de_iata, icao, de_icao]}: #{raw_airport.to_tsv} #{airport.to_tsv}"
    #     end
    #     airport.receive!(raw_airport.airport_attrs)
    #   end
    #   AIRPORTS
    # end

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

    def self.dump_ids(ids)
      "%s\t%s\t%s" % [icao, iata, faa]
    end
    def self.dump_mapping
      [:icao, :iata, :faa].map do |attr|
        "%-50s" % ID_MAP[attr].to_a.sort.map{|id, val| "#{id}:#{val.icao||'    '}|#{val.iata||'   '}|#{val.faa||'   '}"}.join(";")
      end
    end

    def self.dump_info(kind, ids, reconciler, existing, *args)
      ex_str = [existing.map{|el| dump_ids(el.ids) }, "\t\t","\t\t","\t\t"].flatten[0..2]
      puts [kind, dump_ids(ids), dump_ids(reconciler.ids), ex_str, *args, dump_mapping.join("//") ].flatten.join("\t| ")
    end
end
