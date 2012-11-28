require 'log4r'

module Wukong
  class ProcessorBuilder < Hanuman::StageBuilder
    def namespace(*args)
      args.first.is_a?(Class) ? args.first : Wukong::Processor
    end
  end

  # The Processor is the basic unit of computation in Wukong.  A
  # processor can be thought of as an arbitrary function that takes
  # certain inputs and produces certain (or no) outputs.
  #
  # A Processor can be written and tested purely in Ruby and on your
  # local machine.  You can glue processors together
  class Processor < Hanuman::Stage
    
    field :action,   Whatever
    field :log,      Whatever, :default => -> { log = Log4r::Logger.new(self.class.to_s) ; log.outputters = Log4r::StdoutOutputter.new('stdout', formatter: Log4r::PatternFormatter.new(pattern: "%d [%l] %c: %m")) ; log }
    field :notifier, Vayacondios::NotifierFactory, :default => Vayacondios.default_notifier

    def self.describe desc
      @description = desc
    end

    def self.description
      @description
    end

    def self.consumes label
    end

    def self.produces label
    end

    # This is a placeholder method intended to be overridden
    def perform_action(*args) ; end 
    
    # The action attribute is turned into the perform action method
    def receive_action(action)
      self.define_singleton_method(:perform_action, &action)
    end

    # Valid notifier types are currently :http or :log
    # This processor's log is passed to vayacondios
    def receive_notifier(type)
      if type.is_a?(Hash)
        @notifier = Vayacondios::NotifierFactory.receive({type: 'log'}.merge(type))
      else
        @notifier = Vayacondios::NotifierFactory.receive(type: type, log: log)
      end
    end

    # Send information to Vayacondios; data goes in, the right thing happens
    def notify(topic, cargo)
      notifier.notify(topic, cargo)
    end

    # This method is called after the processor class has been instantiated
    # but before any records are given to it to process
    def setup
    end

    # This method is called once per record
    # Override this in your subclass
    def process(record, &emit)
      yield record
    end

    # This method is called to signal the last record has been
    # received but that further processing may still be done, events
    # still be yielded, &c.
    #
    # This can be used within an aggregating processor (like a reducer
    # in a map/reduce job) to start processing the final aggregate of
    # records since the "last record" has already been received.
    def finalize
    end

    # This method is called after all records have been passed.  It
    # signals that processing should stop.
      
    # This method is called after all records have been processed
    def stop
    end

  end
end
