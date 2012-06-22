module Hanuman
  class Stage
    include Gorillib::Builder

    field :name,  Symbol
    field :owner, Whatever

    class_attribute :defined_stages ; self.defined_stages = {}

    def self.make(*args, &blk)
      opts  = args.extract_options!
      attrs = opts.merge(Hash[ self.field_names.rotate(2).zip(args) ].compact)
      new(attrs, &blk)      
    end

    def self.register_stage(arg = nil)
      stage_name = arg || Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
      defined_stages[stage_name.to_sym] = self
    end
    
    def outputs() @outputs ||= {} ; end

    def output(slot_name) outputs[slot_name.to_sym] ; end

    def into(stage, slot_name)
      outputs[slot_name.to_sym] = stage
      owner.connect(self, stage) 
      stage
    end    

  end

  def self.stage(stage_name, &blk)
    stage = Stage.defined_stages.fetch(stage_name) do
      klass_name = Gorillib::Inflector.camelize(stage_name.to_s).to_sym
      const_defined?(klass_name) ? const_get(klass_name) : const_set(klass_name, Class.new(Hanuman::Stage))
    end
    stage.class_eval(&blk) if blk
    Stage.defined_stages[stage_name.to_sym] = stage
  end  
end
