module Wukong  
  class LogFactory

    attr_reader :created_log

    def self.defaults
      Log4r::StderrOutputter.new('console', formatter: Log4r::PatternFormatter.new(pattern: "%l %d [%-20c] -- %m"))
    end

    def self.configure(klass, options = {})
      factory = new(klass, options)
      factory.created_log
    end

    def initialize(logger, config)
      @created_log = logger.is_a?(Log4r::Logger) ? logger : Log4r::Logger.new(logger.to_s)
      outputter(LogFactory.defaults) unless ancestry_has_outputter?(@created_log)
      apply_options(config)
    end

    def ancestry_has_outputter? lgr
      if lgr.respond_to?(:outputters) && !lgr.outputters.empty?
        true
      elsif lgr.respond_to?(:parent) && !lgr.parent.nil?
        ancestry_has_outputter? lgr.parent
      else
        false        
      end
    end
     
    def apply_options config
      config.each_pair do |option, value| 
        begin
          send(option, value)
        rescue
          raise "invalid log option"
        end
      end
    end

    def outputter outptr
      created_log.outputters = outptr
    end

    def level lvl
      created_log.level = lookup_level(lvl.to_sym)
    end

    def lookup_level lvl
      { 
        debug: Log4r::DEBUG,
        info:  Log4r::INFO,
        warn:  Log4r::WARN
      }.fetch(lvl){ raise "invalid log level" }
    end

    def pattern ptrn
      created_log.outputters.each do |output|
        keep_date_format = output.formatter.date_pattern
        output.formatter = Log4r::PatternFormatter.new(pattern: ptrn, date_format: keep_date_format)
      end
    end

    def date_format fmt
      created_log.outputters.each do |output|
        keep_pattern = output.formatter.pattern
        output.formatter = Log4r::PatternFormatter.new(pattern: keep_pattern, date_format: fmt)
      end
    end    
  end

  # Mixin for logging behavior
  module Logging

    def self.included klass
      if klass.ancestors.include?(Gorillib::Model)
        klass.class_eval do
          field(:log, Whatever, :default => ->{ Wukong::LogFactory.configure(self.class) }) 

          def receive_log params
            @log = LogFactory.configure(self.class, params)
          end
        end
      else
        klass.class_attribute :log
        klass.log = LogFactory.configure(klass)
      end
    end    
  end
  
  # Default log. Parent to all logs created in Wukong namespace
  Log = LogFactory.configure(Wukong)
end
