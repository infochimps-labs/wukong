module Wukong
  class Processor < Hanuman::Action
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot

    field :name, Symbol, :default => ->{ self.class.handle }

    # override this in your subclass
    def process(record)
    end

    # passes a record on down the line
    def emit(record)
      output.process(record)
    end

    def bad_record(*args)
      BadRecord.make(*args)
    end

    def self.register_processor(name=nil, &block)
      register_action(name, &block)
    end
  end

  class AsIs < Processor
    # accepts records, emits as-is
    def process(*args)
      emit(*args)
    end
    register_processor
  end

  class Null < Processor
    self.register_processor

    # accepts records, emits none
    def process(*)
      # ze goggles... zey do nussing!
    end
  end

  #
  # Foreach calls a block on every record, and depends on the block to call
  # emit. You can emit one record, many records, or no records, and with any
  # contents. If you'll always emit exactly one record out per record in,
  # you may prefer Wukong::Widget::Map.
  #
  # @example regenerate a wordbag with counts matching the original
  #   foreach{|rec| rec.count.times{ emit(rec.word) } }
  #
  # @see Project
  # @see Map
  class Foreach < Processor
    self.register_processor

    # @param [Proc] proc used for body of process method
    # @yield ... or supply it as a &block arg.
    def initialize(prc=nil, &block)
      prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
      define_singleton_method(:process, prc)
    end

    def self.make(workflow, *args, &block)
      obj = new(*args, &block)
      workflow.add_stage obj
      obj
    end
  end

  #
  # Evaluates the block and emits the result if non-nil
  #
  # @example turn a record into a tuple
  #   map{|rec| rec.attributes.values }
  #
  # @example pass along first matching term, drop on the floor otherwise
  #   map{|str| str[/\b(love|hate|happy|sad)\b/] }
  #
  class Map < Processor
    self.register_processor
    attr_reader :blk

    # @param [Proc] proc to delegate for call
    # @yield if proc is omitted, block must be supplied
    def initialize(blk=nil, &block)
      @blk = blk || block or raise "Please supply a proc or a block to #{self.class}.new"
    end

    def process(*args)
      result = blk.call(*args)
      emit result unless result.nil?
    end

    def self.make(workflow, *args, &block)
      obj = new(*args, &block)
      workflow.add_stage obj
      obj
    end
  end

  #
  # Flatten emits each item in an enumerable as its own record
  #
  # @example turn a document into all its words
  #   input > map{|line| line.split(/\W+/) } > flatten > output
  class Flatten < Processor
    self.register_processor

    def process(iter)
      iter.each{|*args| emit(*args) }
    end
  end


  module CountingProcessor
    extend Gorillib::Concern
    included do
      field :count,     Integer, :doc => 'count of records this run', :default => 0, :writer => :protected
    end

    def setup
      super
      self.count = 0
    end

    # Does not process any records if over limit
    def process(record)
      super(record)
      self.count += 1
    end
  end

end
