module Wukong
  # Common logger
  #
  # Set your own at any time with
  #   Wukong.logger = YourAwesomeLogger.new(...)
  # If you have log4r installed you can use
  #   Wukong.logger = Wukong.default_log4r_logger
  #
  # If Wukong.logger is too much typing for you,
  # use the Log constant
  #
  # Default format:
  #     I, [2009-07-26T19:58:46-05:00 #12332]: Up to 2000 char message
  #
  def self.logger
    @logger ||= default_ruby_logger
  end

  #
  # Log4r logger, set up to produce tab-delimited (and thus, wukong|hadoop
  # friendly) output lines
  #
  def self.default_log4r_logger logger_handle='wukong'
    require 'log4r'
    lgr       = Log4r::Logger.new logger_handle
    outputter = Log4r::Outputter.stderr
    # Define timestamp formatter method
    ::Time.class_eval do def utc_iso8601() utc.iso8601 ; end ; end
    # 2009-07-25T00:12:05Z INFO PID\t
    outputter.formatter  = Log4r::PatternFormatter.new(
      :pattern     => "%d %.4l #{Process.pid}\t%.2000m",
      :date_method => :utc_iso8601
      )
    lgr.outputters = outputter
    lgr
  end

  def self.default_ruby_logger
    require 'logger'
    logger = Logger.new STDERR
    logger.instance_eval do
      def dump *args
        debug args.inspect
      end
    end
    logger
  end

  def self.logger= logger
    @logger = logger
  end
end

#
# A convenient logger.
#
# Define NO_WUKONG_LOG (or define Log yourself) to prevent its creation
#
Log = Wukong.logger unless (defined?(Log) || defined?(NO_WUKONG_LOG))
