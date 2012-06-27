module Wukong
  class Workflow < Hanuman::Graph

    class ActionWithInputs < Hanuman::Action
      def self.make(workflow, *input_stages, &block)
        options  = input_stages.extract_options!
        stage    = new
        workflow.set_stage stage
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
      magic :script, String
      register_action
    end

  end
end
