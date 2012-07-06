require 'spec_helper'
require 'wukong'

describe 'complex dataflow', :only, :examples_spec do

  it 'runs' do
    load Pathname.path_to(:examples, 'dataflow/complex.rb')

    Wukong.dataflow(:series) do

      stages.to_a.first.drive
      # stop
    end

  end
end
