module Wukong
  class Workflow < Hanuman::Graph

    class ActionWithInputs < Hanuman::Action
      def initialize(*input_stages, &block)
        attrs = input_stages.extract_options!
        super(attrs)
        input_stages.map do |input|
          workflow.connect(input, :default, stage, :default)
        end
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
    end

    class Shell < Command
      magic :script, String
      register_action
    end

  end
end
