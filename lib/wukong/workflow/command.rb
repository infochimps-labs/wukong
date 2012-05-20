

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
      collection :inputs,  Hanuman::Stage
      collection :outputs, Hanuman::Stage

      def self.register_action(name=nil, &block)
        name ||= handle
        klass = block_given? ? nil : self
        Wukong::Workflow.register_action(name, klass, &block)
      end

      def set_input(name, stage)
        set_collection_item(:inputs, name, stage)
      end
      def set_output(name, stage)
        set_collection_item(:outputs, name, stage)
      end

    end

    class Shell < Command
    end
  end
end
