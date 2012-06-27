module Hanuman
  class Stage
    include Gorillib::Builder

    magic :name,  Symbol
    magic :owner, Whatever

    def label
      label = @label || self.name
      [owner.try(:label), label].compact.join('.')
    end

    def self.make(*args, &blk)
      opts  = args.extract_options!
      attrs = opts.merge(Hash[ self.field_names.rotate(2).zip(args) ].compact)
      new(attrs, &blk)
    end

    def register_stage(stage_name = nil)
      self.class.register_stage(stage_name)
    end

    def self.register_stage(stage_name = nil)
      klass = self.is_a?(Class) ? self : self.class
      stage_name ||= Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(klass.name)).to_sym
      Hanuman::Universe.defined_stages[stage_name] = klass
      Hanuman::Universe.send(:define_method, stage_name) do |*args, &block|
        stage = Hanuman::Universe.defined_stages[stage_name].make(*args, :owner => self, :name => stage_name)
        set_stage(stage, stage.label) if self.is_a? Hanuman::Graph
        stage
      end
    end

    def links() @links ||= {} ; end

    def link(link_name) links[link_name] ; end

    def >(stage)
      owner.connect(self, stage)
    end

    def outlink(stage, link_name)
      links[link_name] = stage
    end

    def inlink(stage, link_name)
      stage.outlink(self, link_name)
    end

  end
end
