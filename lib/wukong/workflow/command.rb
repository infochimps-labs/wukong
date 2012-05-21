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
      collection :inslots, Hanuman::InputSlot
      collection :outslots, Hanuman::OutputSlot

      def set_input(stage)
        slot = Hanuman::InputSlot.new(
          :name => stage.name, :stage => self, :input => stage)
        self.inslots[stage.name] = slot
      end

      def inputs
        inslots.to_a.map{|slot| slot.input }
      end

      def set_output(stage)
        slot = Hanuman::OutputSlot.new(
          :name => stage.name, :stage => self, :output => stage)
        self.outslots[stage.name] = slot
      end

      def outputs
        outslots.to_a.map{|slot| slot.output }
      end

      def self.make(workflow, stage_name, *input_stages, &block)
        options  = input_stages.extract_options!
        stage    = new(options.merge(
            :name => stage_name, :script => stage_name, :owner => workflow))
        workflow.add_stage stage
        input_stages.map do |input|
          stage.from(input)
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
