module Wukong
  # Common logger
  #
  # Set your own at any time with
  #   Wukong.logger = YourAwesomeLogger.new(...)
  # If you don't have log4r installed call
  #   Wukong.logger = Wukong.default_ruby_logger
  #
  # Default format:
  #     I, [2009-07-26T19:58:46-05:00 #12332]: Up to 2000 char message
  #
  def self.logger
    @logger ||= default_log4r_logger
  end


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
    Log4r::Logger.new STDERR
  end

  def self.logger= logger
    @logger = logger
  end
end
