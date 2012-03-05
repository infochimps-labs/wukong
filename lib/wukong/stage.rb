module Wukong
  registry(:source)
  registry(:sink)
  registry(:streamer)
  registry(:formatter)

  #
  # * **field**: defined attributes of this stage
  #
  class Stage

    # stage to receive emitted messages
    attr_reader :next_stage

    # TODO: implement me
    def self.field(name, type, options)
      attr_accessor(name)
      options[:summary].gsub(/\n\s+/, "\n") if options[:summary]
    end

    def self.alias_field(name, existing_field_name)
      alias_method name, existing_field_name
    end

    def self.action(name, type, options)
      define_method(name){ raise "not implemented" }
    end

    class_attribute :default_action

    def self.description(desc=nil)
      @description = desc if desc
      @description
    end

    field :description, String, :description => 'briefly documents this stage and its purpose'
    alias_field :desc, :description
    field :summary,     String, :description => 'a long-form description of the stage'
    field :next_stage,  Stage, :description => 'stage to send output to'
    field :prev_stage,  Stage, :description => 'stage to receive input from'

    field :actions,     Array, :of => Symbol, :description => 'list of actions this stage responds to'

    # invoked on each record in turn
    # override this in your subclass
    def call(record)
    end

    #
    #
    #

    #
    # Methods
    #

    def start
    end

    # called at the end of a run
    def finally
      next_stage.finally if next_stage
    end

    def tell(event, *info)
      if respond_to?(event)
        self.send(event, *info)
      elsif next_stage
        next_stage.tell(event, *info)
      else
        warn("No next_stage set for #{self}")
        return
      end
    end

    #
    # Graph connections
    #

    def into(stage=nil, &block)
      stage ||= block
      stage = Wukong.create_streamer(:map, stage) if stage.is_a?(Proc)
      @next_stage = stage
    end

    def |(*args, &block)
      into(*args, &block)
    end

    #
    # Graph Sugar
    #

    def select(pred=nil, &block)
      self.into(Wukong::Stage.select(pred, &block))
    end

    def reject(pred=nil, &block)
      self.into(Wukong::Stage.reject(pred, &block))
    end

    def self.select(pred=nil, &block)
      pred ||= block
      case
      when Wukong.streamer_exists?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpFilter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcFilter.new(pred)
      else raise "Can't create a filter from #{pred.inspect}"
      end
    end

    def self.reject(pred=nil, &block)
      pred ||= block
      case
      when Wukong.streamer_exists?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpRejecter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcRejecter.new(pred)
      else raise "Can't create a filter from #{pred.inspect}"
      end
    end

    #
    # Assembly -- find and identify by handle
    #

    def self.handle
      self.to_s.demodulize.underscore.to_sym
    end

    class << self
      # # gets class for given streamer
      # def klass_for(type, handle)
      #   @@registry[type][handle]
      # end

      # # returns a new instance of given type
      # def create(type, klass, *args, &block)
      #   klass = klass_for(type, klass) unless klass.is_a?(Class)
      #   if not klass
      #     raise "Can't create '#{type}' '#{klass}': registry #{all.inspect}"
      #   end
      #   klass.new(*args, &block)
      # end

      # def has(type, obj)
      #   all[type].value_exists?(obj)
      # end

    end

  end
end
