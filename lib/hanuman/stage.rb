module Hanuman
  class Stage
    include Gorillib::Builder

    field :name,  Symbol,   :doc => 'name for this stage; should be unique among other stages on its containing graph'
    field :label, Symbol,   :doc => 'the reference handle for this stage' 
    field :owner, Whatever, :doc => 'the graph this stage sits in'
    
    def self.make(*args, &blk)
      attrs = args.extract_options!
      stage = receive attrs.merge(Hash[ self.field_names.zip(args) ]).compact
      stage.receive!(&blk)
      owner.set_stage(stage.label, stage) if owner
      stage
    end
    
    def outputs() @outputs ||= {} ; end

    def into(stage, slot_name)
      outputs[slot_name.to_sym] = stage
      stage
    end    

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      basename = attribute_set?(:name) ? self.name : self.class.handle
      owner.try(:determine_fullname, self) || basename
      # [owner.try(:fullname), name].compact.join('.')
    end

    def self.handle
      @handle ||= Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end

    #
    # Methods
    #
    # def lookup(stage)
    #   owner.lookup(stage)
    # end

    # #
    # # Graph connections
    # #

    # def notify(msg)
    #   true
    # end

    # def report
    #   self.attributes
    # end

    # def to_key()      name   ; end
    # def key_method() :name ; end
  end
end
