require 'gorillib/utils/capture_output'

shared_context 'hanuman', :helpers => true do

  let :example_graph do
    Hanuman::Graph.new(:name => :pie) do

      graph(:crust) do
        action(:add).input(:flour)
        action(:add).input(:salt)
        # action(:add).input(:shortening)
        #
        stage(:dough).input(:add)
        action(:split).input(:dough) # .output(:ball)

        resource(:ball1).input(:split)

        output( resource(:ball1) )
      end

      # action(:assemble).input(:crust)
      # action(:assemble).input(:filling)
      #
      # action(:bake_pie).input(:assemble)
      #
      # self.input(:bake_pie)
      #
      # # output
      #
      # # graph(:filling) do
      # #   action(:add).input(:cherries)
      # # end
      # #
      # # action(:make_pie).input(:crust)
      # # action(:make_pie).input(:filling)
      # # action(:bake_pie).input(:make_pie)

    end
  end
end
