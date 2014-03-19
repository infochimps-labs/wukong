require 'gorillib/utils/nuke_constants'
require 'gorillib/utils/capture_output'

module Gorillib ;               module Test ;       end ; end
module Meta ; module Gorillib ; module Test ; end ; end ; end

shared_context 'model', :model_spec do
  include Gorillib::TestHelpers

  after(:each){ Gorillib::Test.nuke_constants ; Meta::Gorillib::Test.nuke_constants }

  let(:mock_val){ double('mock value') }

  let(:smurf_class) do
    class Gorillib::Test::Smurf
      include Gorillib::Model
      field :name,       String
      field :smurfiness, Integer
      field :weapon,     Symbol
    end
    Gorillib::Test::Smurf
  end
  let(:papa_smurf   ){ smurf_class.receive(:name => 'Papa Smurf', :smurfiness => 9,  :weapon => 'staff') }
  let(:smurfette    ){ smurf_class.receive(:name => 'Smurfette',  :smurfiness => 11, :weapon => 'charm') }

  let(:smurf_collection_class) do
    smurf_class
    class Gorillib::Test::SmurfCollection < Gorillib::ModelCollection
      include Gorillib::Collection::ItemsBelongTo
      self.item_type        = Gorillib::Test::Smurf
      self.parentage_method = :village
    end
    Gorillib::Test::SmurfCollection
  end

  let(:smurf_village_class) do
    smurf_class ; smurf_collection_class
    module Gorillib::Test
      class SmurfVillage
        include Gorillib::Model
        field      :name,   Symbol
        collection :smurfs, SmurfCollection, item_type: Smurf, key_method: :name
      end
    end
    Gorillib::Test::SmurfVillage
  end

  let(:smurfhouse_class) do
    module Gorillib::Test
      class Smurfhouse
        include Gorillib::Model
        field   :shape, Symbol
        field   :color, Symbol
      end
    end
    Gorillib::Test::Smurfhouse
  end

end

shared_context 'builder', :model_spec, :builder_spec do
  let(:engine_class) do
    class Gorillib::Test::Engine
      include Gorillib::Builder
      magic    :name,         Symbol, :default => ->{ "#{owner? ? owner.name : ''} engine"}
      magic    :carburetor,   Symbol, :default => :stock
      magic    :volume,       Integer, :doc => 'displacement volume, in in^3'
      magic    :cylinders,    Integer
      member   :owner,        Whatever
      self
    end
    Gorillib::Test::Engine
  end

  let(:car_class) do
    engine_class
    class Gorillib::Test::Car
      include Gorillib::Builder
      magic    :name,          Symbol
      magic    :make_model,    String
      magic    :year,          Integer
      magic    :doors,         Integer
      member   :engine,        Gorillib::Test::Engine
      self
    end
    Gorillib::Test::Car
  end

  let(:garage_class) do
    car_class
    class Gorillib::Test::Garage
      include Gorillib::Builder
      collection :cars,       Gorillib::Test::Car, key_method: :name
      self
    end
    Gorillib::Test::Garage
  end

  let(:wildcat) do
    car_class.receive( :name => :wildcat,
      :make_model => 'Buick Wildcat', :year => 1968, :doors => 2,
      :engine => { :volume => 455, :cylinders => 8 } )
  end
  let(:ford_39) do
    car_class.receive( :name => :ford_39,
      :make_model => 'Ford Tudor Sedan', :year => 1939, :doors => 2, )
  end
  let(:garage) do
    garage_class.new
  end
  let(:example_engine) do
    engine_class.new( :name => 'Geo Metro 1.0L', :volume => 61, :cylinders => 3 )
  end

end
