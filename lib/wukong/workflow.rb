module Wukong
  class Workflow  < Hanuman::Graph
    collection :inputs,  Hanuman::Stage
    collection :outputs, Hanuman::Stage

    def set_output(sink)
      stages.to_a.last.set_output :_, sink
    end

    #
    # lifecycle
    #

    def setup
      stages.each_value{|stage| stage.setup}
    end

    def stop
      stages.each_value{|stage| stage.stop}
    end

    def shell(name, *input_stages, &block)
      options = input_stages.extract_options!
      shell_stage = Wukong::Workflow::Shell.new(options.merge(:name => name))
      add_stage shell_stage
      input_stages.map do |input|
        other = resource(input)
        connect(other, shell_stage, other.name, other.name)
      end
    end

  end
end
