module Wukong
  class Workflow

    #
    # A command is a workflow action that runs a type of command on many inputs,
    # under a given configuration, into named outputs.
    #
    # @example
    #   bash 'create_archive.sh', filenames, :compression_level => 9 > 'archive.tar.gz'
    #
    class Command < Hanuman::Action

      def self.make(workflow, stage_name, *input_stages, &block)
        options  = input_stages.extract_options!
        stage    = new(options.merge(
            :name => stage_name, :script => stage_name, :owner => workflow))
        workflow.add_stage stage
        input_stages.map do |input|
          slot_name = input.is_a?(Symbol) ? input : input.name
          stage.from(input, slot_name, slot_name)
        end
        stage
      end

    end

    class Shell < Command
      field :script, String
      register_action
    end

  end
end
