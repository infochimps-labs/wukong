class Wukong::Workflow < Hanuman::Graph

  class Container  < Hanuman::Resource  ; end

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
    consumes :container

    def self.make(workflow, container, *input_stages, &block)
      options = input_stages.extract_options!
      super(workflow, *input_stages, options.merge(:container => container), &block)
    end
  end
end

# TODO: make repeated calls not retrieve object again -- it seems lookup is the special case, not creation.

class Warrant ; extend Wukong::Universe ; end
Warrant.workflow(:cherry_pie) do
  graph(:crust) do
    add_to(:small_bowl, :flour, :salt, :shortening) > :crumbly_mixture

    # equvalently:
    #   add_to(:crumbly_mixture, :buttermilk) > :dough
    add_to(:crumbly_mixture) << :buttermilk > :dough

    split(:dough).into(:ball_for_top, :ball_for_bottom)

    # equvalently:
    #  combine << :pie_tin << (rolling_pin << :ball_for_bottom) > :pie_tin_with_crust
    combine(:pie_tin, (rolling_pin << :ball_for_bottom)).into(:pie_tin_with_crust)

    self << stage(:ball_for_bottom)
    self << stage(:pie_tin_with_crust)
  end

  graph(:filling) do
    drain(:cherries).into(:drained_cherries, :cherry_juice)
    add_to(:saucepan, :corn_starch, :sugar, :salt) >
      whisk << :cherry_juice >
      :raw_goop
    cook(:raw_goop, :trigger => 'goop slightly thickened') > :goop
    add_to(:goop, :drained_cherries, :butter) > cool > self
  end

  rolling_pin << stage(:crust).stage(:ball_for_top) > :top_crust

  raw_pie = add_to(stage(:crust).stage(:pie_tin_with_crust), :filling)
  raw_pie << :top_crust

  cook(:oven, raw_pie) > cool(:wire_rack) > self

end
