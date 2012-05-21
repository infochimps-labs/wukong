module Wukong
  class Workflow

    class ActionWithInputs < Hanuman::Action
      include Hanuman::Slottable
      include Hanuman::SplatInputs
      include Hanuman::SplatOutputs

      def self.make(workflow, *input_stages, &block)
        options  = input_stages.extract_options!
        stage    = new
        workflow.add_stage stage
        input_stages.map do |input|
          workflow.connect(input, stage)
        end
        stage.receive!(options, &block)
        stage
      end
    end

    #
    # A command is a workflow action that runs a type of command on many inputs,
    # under a given configuration, into named outputs.
    #
    # @example
    #   bash 'create_archive.sh', filenames, :compression_level => 9 > 'archive.tar.gz'
    #
    class Command < ActionWithInputs

      def self.make(workflow, stage_name, *input_stages, &block)
        options  = input_stages.extract_options!
        super(workflow, *input_stages, options.merge(:name => stage_name, :script => stage_name), &block)
      end
    end

    class Shell < Command
      field :script, String
      register_action
    end

  end
end
