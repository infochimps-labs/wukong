class Wukong::Workflow < Hanuman::Graph

  class Container  < Hanuman::Product
    register_stage
  end

  class Qty < Hanuman::Product
    doc 'a quantity of an ingredient'
    register_stage
    field :amount, String, :position => 1
  end
  class Utensil    < Hanuman::Product ; register_stage ; end

  class Cook       < ActionWithInputs
    register_action
    field :trigger, String, :doc => 'stop cooking when this event is reached'
  end

  class Cool       < ActionWithInputs ; register_action ; end

  class Combine    < ActionWithInputs ; register_action ; end
  class Split      < ActionWithInputs ; register_action ; end
  class RollingPin < ActionWithInputs ; register_action ; end
  class Drain      < ActionWithInputs ; register_action ; end
  class Whisk      < ActionWithInputs ; register_action ; end

  class AddTo < ActionWithInputs
    register_action

    magic :container, Hanuman::Stage
  end

end

Hanuman::Graph.class_eval{  alias_method :product, :product }

# TODO: make repeated calls not retrieve object again -- it seems lookup is the special case, not creation.

#
# Make Warrant happy
#
# class Warrant ; extend Wukong::Universe ; end
Wukong.workflow(:cherry_pie) do

  subgraph(:crust) do

    add_to(container(:small_bowl),
      qty(:flour,      '3 cups'),
      qty(:salt,       '1.5 tsp'),
      qty(:shortening, '6 tbsp')
      ) > product(:crumbly_mixture)

    # equvalently:
    #   add_to(:crumbly_mixture, qty(:buttermilk)) > product(:dough)
    add_to(:crumbly_mixture)  << qty(:buttermilk)  > product(:dough)

    split(:dough) do
      into owner.product(:ball_for_top)
      into owner.product(:ball_for_bottom)
    end

    # equvalently:
    #  combine << :pie_tin << (rolling_pin << :ball_for_bottom) > :pie_tin_w_crust
    combine(container(:pie_tin),
      (rolling_pin << :ball_for_bottom)
      ).into(product(:pie_tin_w_crust))

  end

  subgraph(:filling) do

    qty(:cherries, '4 cups')

    drain(:cherries).into(
      product(:drained_cherries),
                                      ).into( # FIXME - should be a multiple-output
      product(:cherry_juice)
      )
    qty(:butter, '2 tbsp, cut up')
    add_to(container(:saucepan),
      qty(:corn_starch, '1/3 cup'),
      qty(:sugar, '1.5 cups'),
      qty(:salt, '1 dash')) >
      whisk << :cherry_juice >
      product(:raw_goop)
    cook(:raw_goop, :trigger => 'goop slightly thickened') > product(:goop)
    add_to(:goop, :drained_cherries, :butter) > cool > product(:output)
  end

  rolling_pin << stage(:crust).stage(:ball_for_top) > product(:top_crust)

  raw_pie = add_to(
    stage(:crust).stage(:pie_tin_w_crust),
    stage(:filling).product(:output))
  raw_pie << :top_crust

  x = utensil(:oven)

  cook(utensil(:oven), raw_pie) > cool(utensil(:wire_rack))

end
