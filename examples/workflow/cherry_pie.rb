Wukong.workflow(:cherry_pie) do
  # graph(:crust) do
    shell :combine, :small_bowl, :flour

    # action(:add).input(:flour)
    # action(:add).input(:salt)
    # # action(:add).input(:shortening)
    # #
    # stage(:dough).input(:add)
    # action(:split).input(:dough) # .output(:ball)
    #
    # resource(:ball1).input(:split)
    # resource(:ball2).input(:split)

    # action(:flatten) << resource(:ball1) << resource(:rolling_pin) << resource(:cutting_board)
    # resource(:crust_base) << action(:flatten)
    #
    # output( resource(:crust_base) )

  #end

  # action(:assemble).input(:crust)
  # action(:assemble).input(:filling)
  #
  # action(:bake_pie).input(:assemble)
  #
  # self.input(:bake_pie)
  #
  # # output
  #
  # graph(:filling) do
  #   action(:add).input(:cherries)
  # end
  #
  #action(:make_pie) << graph(:crust).output
  # action(:bake_pie).input(:make_pie_out, action(:make_pie).output )

  p self
end
