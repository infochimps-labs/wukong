module Wukong

  #
  # Describe a dataflow of sources, processors and sinks.
  #
  #
  class Dataflow < Hanuman::Graph

  end

  class Chain < Dataflow
    include Hanuman::Inlinkable
    include Hanuman::Outlinkable
    consume :input,  Whatever
    produce :output, Whatever

    def set_source(*args)
      input.set_source(*args)
    end

    def set_sink(*args)
      output.set_sink(*args)
    end
  end

end
