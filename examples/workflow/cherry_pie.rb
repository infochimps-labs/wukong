class Wukong::Workflow < Hanuman::Graph
  class Container  < Hanuman::Resource  ; end

  class Cook       < ActionWithInputs
    register_action
    field :trigger, String, :doc => 'stop cooking when this event is reached'
  end
  class Cool       < ActionWithInputs          ; register_action ; end

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

# TODO: make repeated calls not retrieve object again -- it seems lookup is the special case, not creation.

#
# Make Warrant happy
#
Wukong.workflow(:cherry_pie) do
  graph(:crust) do
    add_to(:small_bowl, :flour, :salt, :shortening) > :crumbly_mixture

    # equvalently:
    #   add_to(:crumbly_mixture, :buttermilk) > :dough
    add_to(:crumbly_mixture) << :buttermilk > :dough

    resource(:ball_for_top)
    resource(:ball_for_bottom)
    split(:dough).into(:ball_for_top, :ball_for_bottom)

    # equvalently:
    #  combine << :pie_tin << (rolling_pin << :ball_for_bottom) > :pie_tin_with_crust
    combine(:pie_tin, (rolling_pin << :ball_for_bottom)).into(:pie_tin_with_crust)

    self << stage(:ball_for_bottom)
    self << stage(:pie_tin_with_crust)
  end

  p graph(:crust)

  graph(:filling) do
    drain(:cherries).into(:drained_cherries, :cherry_juice)
    add_to(:saucepan, :corn_starch, :sugar, :salt) >
      whisk << :cherry_juice >
      :raw_goop
    cook(:raw_goop, :trigger => 'goop slightly thickened') > :goop
    add_to(:goop, :drained_cherries, :butter) > cool > self
  end

  p stage(:crust)
  p stage(:crust).stages
  rolling_pin << stage(:crust).stage(:ball_for_top) > :top_crust

  raw_pie = add_to(stage(:crust).stage(:pie_tin_with_crust), :filling)
  raw_pie << :top_crust

  cook(:oven, raw_pie) > cool(:wire_rack) > self

end
