# Hanuman core

Hanuman.stage(:some_stage)
Hanuman.stage(:another_stage)

Hanuman.graph(:simple_graph) do

  some_stage > another_stage
  
end

Hanuman.graph(:chained) do

  one_stage > simple_graph
  # one_stage.into(simple_graph)
end

Hanuman.graph(:split) do

  a_stage <[ 
            b_stage > chained 
            c_stage
           ]

  # a_stage.into_multi([b_stage.into(chained), c_stage])
end

Hanuman.action(:yell) do
  
  perform{ "HI THERE" }
  
end

# Wukong Core

class Wukong::Processor < Hanuman::Action
  
  def perform
  end

end

Wukong.processor(:change) do

  def process(record)
    yield(record.to_s << 'changed')
  end

end

Wukong.dataflow(:split) do


end

