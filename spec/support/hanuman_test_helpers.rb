require 'gorillib/utils/capture_output'

shared_context 'hanuman', :helpers => true do

  let :example_graph do
    Hanuman::Graph.new(:name => :pie) do

      graph(:crust) do
        action(:add).input(:flour)
        action(:add).input(:salt)
        action(:add).input(:shortening)
        stage(:dough).input(:add) # .input :add, action(:add).attributes
        action(:split).input(:dough).output(:ball)
      end

      action(:make_pie).input(:crust)
      action(:make_pie).input(:filling)
      action(:bake_pie).input(:make_pie)

    end
  end
end
