require 'spec_helper'
require 'wukong'

require 'gorillib/model'
require 'gorillib/model/factories'
require 'gorillib/model/serialization'
require 'gorillib/model/serialization/csv'

load Pathname.path_to(:examples, 'munging/airline_flights/identifiers.rb')

describe Airport::IdMapping, :only do
  it 'loads and reconciles' do
    described_class.load(Pathname.path_to(:data, 'airline_flights'))
    #
    Airport::IdMapping::ID_MAPPINGS.each do |identifier, hsh|
      hsh.each do |id, id_mapping|
        # puts [identifier, id, id_mapping.to_tsv].join("\t")
      end
    end
  end
end
