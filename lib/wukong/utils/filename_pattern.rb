module Wukong
  module Utils
    class FilenamePattern
      attr_accessor :pattern
      def initialize pattern
        self.pattern = pattern
      end

      #
      # walk through pattern, replacing tokens (eg :time or :pid) with the
      # corresponding value.
      #
      def make
        @timestamp = Time.now.utc.to_flat
        val = pattern.gsub(/:\w+/){|token| token_val(token)  }
        @timestamp = nil
        val
      end

      #
      # substitute for token
      #
      def token_val token
        p token
        case token
        when ':pid'        then pid
        when ':hostname'   then hostname
        when ':datetime'   then @timestamp
        when ':date'       then @timestamp[ 0..7]
        when ':time'       then @timestamp[ 8..13]
        when ':hour'       then @timestamp[ 8..9]
        when ':min'        then @timestamp[10..11]
        when ':sec'        then @timestamp[12..13]
        else
          raise "Don't know how to encode token #{token}"
        end
      end

      # Memoized: the hostname for the machine running this script.
      def hostname
        @hostname ||= ENV['HOSTNAME'] || `hostname`
      end
      # Memoized: the Process ID for this invocation.
      def pid
        @pid ||= Process.pid
      end

      # Characters deemed safe in a filename;
      SAFE_CHARS = 'a-zA-Z0-9_\-\.\+\/\;'
      def self.sanitize str
        str.gsub(%r{[^#{SAFE_CHARS}]+}, '-')
      end
    end
  end
end
