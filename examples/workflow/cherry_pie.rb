class Wukong::Workflow
  class Mix < Shell
    register_action
  end
  # def mix(name, *input_stages, &block)
  #   options = input_stages.extract_options!
  #   shell(name, *input_stages, options.merge(
  #       :command_factory => Wukong::Workflow::Mix), &block)
  # end

  class Split < Command
    register_action
  end

  class Flatten < Command
    register_action
  end
end

# TODO: repeated calls don't retrieve object again

Wukong.workflow(:cherry_pie) do
  graph(:crust) do
    mix(:small_bowl_a, :flour, :salt, :shortening) > :crumbly_mixture

    mix(:small_bowl_b, :crumbly_mixture, :buttermilk) > :dough

    split(:a) << :dough > :ball
  end

  graph(:assemble) do
    flatten(:rolling_pin, owner.graph(:crust) )
  end

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
