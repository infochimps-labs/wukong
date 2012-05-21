class Wukong::Workflow
  class Container  < Hanuman::Resource ; end
  class Combine    < Hanuman::Action  ; register_action ; end
  class AddTo      < Shell   ; register_action ; end
  class Split      < Hanuman::Action ; register_action ; end
  class RollingPin < Hanuman::Action ; register_action ; end
  class Cook       < Command ; register_action ; end
  class Cool       < Command ; register_action ; end
end

# TODO: repeated calls don't retrieve object again

Wukong.workflow(:cherry_pie) do
  graph(:crust) do
    add_to(:small_bowl_a, :flour, :salt, :shortening) > :crumbly_mixture

    combine << :crumbly_mixture <<
      :buttermilk > :dough

    two_balls = split << :dough
    two_balls > :ball_for_top
    two_balls > :ball_for_bottom

    combine <<
      :pie_tin  <<
      (rolling_pin << :ball_for_bottom) >
      :pie_tin_with_crust
  end

  graph(:filling) do
    add_to(:saucepan, :cherries, :corn_starch) > self
  end

  rolling_pin << stage(:crust).stage(:ball_for_top) > :top

  combine << stage(:crust).stage(:pie_tin_with_crust) << :filling << :top > :raw_pie

  cook(:oven, :raw_pie) > cool(:wire_rack) > self

end
