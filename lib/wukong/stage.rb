module Wukong

  #
  # * **field**: defined attributes of this stage
  #
  module Stage
    extend ActiveSupport::Concern

    # stage to receive emitted messages
    attr_reader :next_stage
    # graph this stage belongs to
    attr_accessor :graph

    # invoked on each record in turn
    # override this in your subclass
    def call(record)
    end

    #
    #
    #

    # passes a record on down the line
    def emit(record, status=nil, headers={})
      next_stage.call(record) if next_stage
    end

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
      stage = self.graph.add_stage(:streamer, :map, stage) if stage.is_a?(Proc)
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

    def to_s
      "<~" + [
        self.class.handle,
        self.instance_variables.reject{|iv| iv.to_s =~ /^@(graph|next_stage|prev_stage)$/ }.map{|iv| "#{iv}=#{self.instance_variable_get(iv)}"  },
        ].flatten.compact.join(" ") + "~>"
    end

    module ClassMethods

      #
      # Assembly -- find and identify by handle
      #

      def handle
        self.to_s.demodulize.underscore.to_sym
      end

      def class_defaults
        field :description, String, :description => 'briefly documents this stage and its purpose'
        alias_field :desc, :description
        field :summary,     String, :description => 'a long-form description of the stage'
        field :next_stage,  Stage, :description => 'stage to send output to'
        field :prev_stage,  Stage, :description => 'stage to receive input from'
      end

      # TODO: implement me
      def field(name, type, options={})
        attr_accessor(name)
        options[:summary].gsub(/([\r\n])\s+/, "\\1\n") if options[:summary]
      end

      def alias_field(name, existing_field_name)
        alias_method name, existing_field_name
      end

      def description(desc=nil)
        @description = desc if desc
        @description
      end

    end
    included do
      self.class_defaults
    end
  end
end
