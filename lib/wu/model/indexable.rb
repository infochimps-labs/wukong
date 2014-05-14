# require 'gorillib/model/serialization'
# require 'gorillib/model/serialization/tsv'
# require 'gorillib/array/hashify'

module Gorillib
  module Model

    #
    # @example
    #   class Airport
    #     include Gorillib::Model::Indexable
    #     # ... define model
    #     index_on :icao_code, :city
    #   end
    #   Airport.for_icao_code('KAUS') #=> #<Airport icao_code="KAUS" ... >
    #   Airport.for_city('Austin')    #=> #<Airport icao_code="KAUS" ... >
    #
    # You must implement a `load` method
    #
    module Indexable
      extend Gorillib::Concern

      included do |base|
        base.class_attribute :lookups, instance_writer: false
        self.lookups ||= []
      end

      module ClassMethods

        # # Implement a load method, returning an array of values
        # def load
        #   @values = load_tsv(Pathname.of(:iso_code_data, "#{handle}.tsv"))
        # end

        def values
          @values ||= Array.new
        end

        def flush_lookups
          lookups.each{|idx| remove_instance_variable("@#{idx}") if instance_variable_defined?("@#{idx}") }
        end

        #
        # @example
        #   class Airport
        #     index_on :icao_code, [:city, :cities]
        #   end
        #   Airport.for_icao_code('KAUS') #=> #<Airport icao_code="KAUS" ... >
        #   Airport.for_city('Austin')    #=> #<Airport icao_code="KAUS" ... >
        #
        # NOTE: `.#{key_name}_index` method is NOT part of the framework interface.
        # only the `.for_#{keyname}` method is suported.
        def index_on(*key_names)
          self.lookups += key_names
          self.lookups.uniq!
          #
          key_names.each do |key_name, index_name|
            index_name ||= "#{key_name}_index"
            class_eval <<-EOV, __FILE__, __LINE__+1
            class << self
              def #{index_name}                                # def name_index
                @#{index_name} ||=                             #   @name_index ||=
                  Hash[values.map{|el| [el.#{key_name}, el] }] #     Hash[values.map{|el| [el.name, el] }]
              end                                              # end
              # protected(:#{index_name})                      # protected :name_index
            end
EOV

            instance_eval <<-EOV, __FILE__, __LINE__+1
              def for_#{key_name}(*args, &block)               # def for_name(*args, &block)
                #{index_name}.fetch(*args, &block)             #   name_index.fetch(*args, &block)
              end                                              # end
EOV
            end
        end
      end
    end

  end
end
