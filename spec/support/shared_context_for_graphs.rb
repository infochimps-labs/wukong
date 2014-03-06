shared_context "graphs" do

  let(:empty_graph) do
    Hanuman::Graph.receive({})
  end

  let(:single_stage_graph) do
    Hanuman::Graph.receive({stages: {first: Hanuman::Stage.receive(label: :first)}})
  end
  
  let(:graph) do
    Hanuman::Graph.receive(stages: {
                             first_a: Hanuman::Stage.receive(label: :first_a), # ancestor
                             first_b: Hanuman::Stage.receive(label: :first_b), # ancestor, 
                             second:  Hanuman::Stage.receive(label: :second),  # ancestor, descendent
                             third_a: Hanuman::Stage.receive(label: :third_a), # ancestor, descendent
                             third_b: Hanuman::Stage.receive(label: :third_b), #           descendent
                             fourth:  Hanuman::Stage.receive(label: :fourth),  #           descendent
                           },
                           links: [
                                   Hanuman::LinkFactory.connect(:simple, :first_a, :second),
                                   Hanuman::LinkFactory.connect(:simple, :first_b, :second),
                                   Hanuman::LinkFactory.connect(:simple, :second, :third_a),
                                   Hanuman::LinkFactory.connect(:simple, :second, :third_b),
                                   Hanuman::LinkFactory.connect(:simple, :third_a, :fourth),
                                  ]
                           )
  end

  let(:empty_tree) do
    Hanuman::Tree.receive({})
  end

  let(:single_stage_tree) do
    Hanuman::Tree.receive({stages: { first: Hanuman::Stage.receive(label: :first)}})
  end
  
  let(:tree) do
    Hanuman::Tree.receive(stages: {
                            # important to mix up the order here so we
                            # can ensure that tree-sorting is working.
                            first:   Hanuman::Stage.receive(label: :first),   # ancestor,
                            third_b: Hanuman::Stage.receive(label: :third_b), #           descendent
                            second:  Hanuman::Stage.receive(label: :second),  # ancestor, descendent
                            fourth:  Hanuman::Stage.receive(label: :fourth),  #           descendent
                            third_a: Hanuman::Stage.receive(label: :third_a), # ancestor, descendent
                          },
                          links: [
                                  Hanuman::LinkFactory.connect(:simple, :first,  :second),
                                  Hanuman::LinkFactory.connect(:simple, :second, :third_a),
                                  Hanuman::LinkFactory.connect(:simple, :second, :third_b),
                                  Hanuman::LinkFactory.connect(:simple, :third_a, :fourth),
                                 ]
                          )
  end

end
