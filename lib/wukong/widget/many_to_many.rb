module Wukong
  module Widget

    #
    # Accepts records from multiple input stages.
    # Passes each received record to all its output sinks.
    #
    class ManyToMany < Hanuman::Stage
      register_stage
      doc 'Accepts records from multiple input stages. Passes each received record to all its output sinks.'

      include Hanuman::SplatInputs
      include Hanuman::SplatOutputs

      def process(record)
        emit(record)
      end

      def emit(record)
        sinks.each do |sink|
          sink.process(record)
        end
      end

    end
  end
end
