require 'vayacondios-client'

Settings.define :monitor_interval, :default => 50_000, :type => Integer

module Wukong
  class ProcessorError < StandardError ; end

  #
  # Processor -- the primary participant in a dataflow
  #
  class Processor < Hanuman::Action
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    field :name, Symbol, :default => ->{ self.class.to_s.underscore }
    field :count, Integer, doc: 'Number of records seen this run', default: 0

    # override this in your subclass
    def process(record)
    end

    # passes a record on down the line
    def emit(record)
      self.count += 1
      if (count % Settings.monitor_interval.to_i == 0)
        log.info "emit\t%-23s\t%-47s\t%s" % [self.class, self.inspect, record.inspect]
      end
      (@sink||=self.sink).process(record)
    rescue Wukong::ProcessorError
      raise
    rescue StandardError => err
      next_block = output.name rescue "(bad stage)"
      log.warn "#{self}: error emitting #{next_block}: #{err.message}"
      raise Wukong::ProcessorError, err.message, err.backtrace
    rescue StandardError => err ; err.polish("#{self.graph_id}: #{record.inspect} to #{@sink.inspect(false)}") rescue nil ; raise
    end

    def bad_record(*args)
      Log.error( { :contents => args }.to_json[0..1024] )
      # BadRecord.make(*args)
    end

    def self.register_processor(name=nil, &block)
      register_action(name, &block)
    end
    
    include Vayacondios::Notifications
    
    class_attribute :log
    self.log = Log
    
    config :error_handler, Vayacondios::NotifierFactory, :default => ->{ Vayacondios::NotifierFactory.receive(type: 'log', log: self.log) }
    
    def bad_record(record, options = {})
      error_handler.notify(record, options.merge(level: 'error'))
    end

    class << self ; alias_method :register_processor, :register_action ; end
  end

  class AsIs < Processor
    register_processor

    # accepts records, emits as-is
    def process(*args)
      emit(*args)
    end
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
    def initialize(*args, &block)
      attrs = args.extract_options!
      @blk = block || args.shift || attrs.delete(:blk) or raise "Please supply a proc or a block to #{self.class}.new"
      super(*args, attrs){}
      define_singleton_method(:process, @blk)
    end

    def inspect
      super[0..-2] << " ->(#{@blk.parameters.join(',')}){#{@blk.source_location.join(':')}}>"
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
    field :name, Symbol, :position => 0
    self.register_processor
    attr_reader :blk

    # @param [Proc] proc to delegate for call
    # @yield if proc is omitted, block must be supplied
    def initialize(*args, &block)
      attrs = args.extract_options!
      @blk = block || attrs.delete(:blk) or raise "Please supply a proc or a block to #{self.class}.new"
      super(*args, attrs){}
      define_singleton_method(:call, @blk)
    end

    def inspect(*)
      super[0..-2] << " ->(#{@blk.parameters.join(',')}){#{(@blk.source_location||[]).join(':')}}>"
    end

    def process(*args)
      result = call(*args)
      emit result unless result.nil?
    end
  end

  #
  # Flatten emits each item in an enumerable as its own record
  #
  # @example turn a document into all its words
  #   source > map{|line| line.split(/\W+/) } > flatten > sink
  class Flatten < Processor
    self.register_processor

    def process(iter)
      iter.each{|*args| emit(*args) }
    end
  end
end
