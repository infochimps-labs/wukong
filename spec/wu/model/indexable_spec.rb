require 'spec_helper'
require 'gorillib/model'
require 'gorillib/pathname'
#
require 'gorillib/model/serialization'
require 'gorillib/model/serialization/tsv'
require 'gorillib/array/hashify'
#
require 'gorillib/model/indexable'

describe Gorillib::Model::Indexable, :model_spec, :only do
  let(:mock_array){ mock('array') }
  let(:country_code_class) do
    module Gorillib::Test
      remove_const(:CountryCode) if defined?(CountryCode)
      class CountryCode
        include Gorillib::Model
        include Gorillib::Model::Indexable

        field :alpha_2_code,     String, position: 0
        field :name,             String, position: 1

        def self.load
          [ new('dj', 'Djibouti'),
            new('us', 'United States of America'),
          ]
        end
      end
    end
    Gorillib::Test::CountryCode
  end
  let(:djibouti){ country_code_class.new('dj', 'Djibouti') }
  let(:usa     ){ country_code_class.new('us', 'United States of America') }

  context '.load' do
    subject{ country_code_class.load }
    it{ should == [djibouti, usa] }
  end

  context '.values' do
    # before{ country_code_class.send(:remove_instance_variable, '@values') }
    it 'gets its values from .load' do
      country_code_class.should_receive(:load).once.and_return mock_array
      country_code_class.values.should equal(mock_array)
    end
    it 'memoizes once it is called' do
      country_code_class.should_receive(:load).once.and_return mock_array
      country_code_class.values.should equal(mock_array)
      country_code_class.values.should equal(mock_array)
    end
  end

  context '.index_on' do
    it 'defines a .for_foo method' do
      country_code_class.should_not respond_to(:for_name)
      country_code_class.index_on(:name)
      country_code_class.should respond_to(:for_name)
      country_code_class.protected_methods.should include(:name_index)
    end
  end

  context '.for_foo' do
    before{ country_code_class.index_on :name }
    context 'behaves like Hash#fetch:' do
      context 'when key is not present' do
        it 'retrieves a value if in the index' do
          country_code_class.for_name('Djibouti').should == djibouti
        end
      end
      context 'when key is not present' do
        it 'and no default it raises KeyError' do
          expect{ country_code_class.for_name('Yo Mama') }.to raise_error(KeyError, 'key not found: "Yo Mama"')
        end
        it 'returns default value if given' do
          yo_mama = country_code_class.for_name('Yo Mama', 'wears combat boots')
          yo_mama.should == 'wears combat boots'
        end
        it 'calls block if given' do
          she = nil
          so_fat = country_code_class.for_name('Yo Mama'){ she = 'sits around the house' ; 'when she sits' }
          so_fat.should == 'when she sits'
          she.should    == 'sits around the house'
        end
      end
    end
  end

end
