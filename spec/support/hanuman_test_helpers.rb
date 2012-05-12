require 'gorillib/utils/capture_output'

shared_context 'hanuman', :helpers => true do

  let :example_graph do
    Hanuman::Graph.new(:name => :pie) do

      stage(:make_pie).input(:crust)
      stage(:make_pie).input(:filling)
      stage(:bake_pie).input(:make_pie)

      output(:bake_pie)
    end
  end
end
