require 'spec_helper'
require 'wukong'

require 'hanuman/graphvizzer'
require 'hanuman/graphviz'


describe 'cherry_pie' do

  it 'fiddles' do

    Wukong.workflow(:cherry_pie) do
      Log.dump self

      graph(:crust) do
        Log.dump self
        action(:bob)
      end

      Log.dump graph(:crust)

    end
  end
end
