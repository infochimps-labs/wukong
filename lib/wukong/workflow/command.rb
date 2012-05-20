

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

      # def self.register_action(name=nil, &block)
      #   name ||= handle
      #   klass = block_given? ? nil : self
      #   Wukong::Graph.register_action(name, klass, &block)
      # end

      def self.register_action(stage_type=nil, &block)
        stage_type ||= handle ; klass = self
        Hanuman::Graph.send(:define_method, stage_type) do |*args, &block|
          begin
            workflow = self
            klass.make(workflow, *args, &block)
          rescue StandardError => err
            err.polish_2("adding #{stage_type} to #{self.name} on #{args}") rescue nil
            raise
          end
        end
      end

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
      # def fullname
      #   "#{super}:#{script}"
      # end

      register_action
    end

  end
end
