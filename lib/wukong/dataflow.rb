module Wukong

  #
  # Describe a dataflow of sources, processors and sinks.
  #
  #
  class Dataflow < Hanuman::Graph

    #
    # lifecycle
    #

    def setup
      stages.each_value{|stage| stage.setup}
    end

    # FIXME -- this is ugly, and evidence to  consider in the "Where does an input live" conundrum
    #   ... or it means that we're thinking about message propogation wrong.

    def stop
      source_stages.each{|stage| stage.stop}
      process_stages.each{|stage| stage.stop}
      sink_stages.each{|stage| stage.stop}
    end

    def source_stages()  stages.to_a.select{|st| st.source? }  end
    def process_stages() stages.to_a.select{|st| (not st.source?) && (not st.sink?) }  end
    def sink_stages()    stages.to_a.select{|st| st.sink?   }  end

  end
end
