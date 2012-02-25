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
    return @logger if defined?(@logger)
    require 'logger'
    @logger = Logger.new STDERR
    @logger.instance_eval do
      def dump *args
        debug args.inspect
      end
    end
    @logger
  end

  def self.logger= logger
    @logger = logger
  end
end

#
# A convenient logger.
#
# define Log yourself to prevent its creation
#
Log         = Wukong.logger       unless defined?(Log)

