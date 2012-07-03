module Hanuman

  #
  # `Action` stages represent transforms of data.
  #
  #
  #
  class Action < Stage

    def source?() false ; end
    def sink?()   false ; end

    def self.register_action(meth_name=nil, &block)
      meth_name ||= stage_type ; klass = self
      #
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          # create stage
          attrs = args.extract_options!
          stage = klass.new(*args, attrs.merge(:owner => self), &block)
          # label and add to grpeh
          label = stage.read_attribute(:name) || next_label_for(stage)
          set_stage(label, stage)
        rescue StandardError => err ; err.polish("adding #{meth_name} to #{self.name} on #{args}") rescue nil ; raise ; end
      end
    end

  end

end
