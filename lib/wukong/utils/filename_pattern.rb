module Wukong
  module Utils
    class FilenamePattern
      # Characters deemed safe in a filename;
      SAFE_CHARS = 'a-zA-Z0-9_\-\.\+\/\;'

      #
      # usable in
      #
      def token_val token, timestamp_str
        case token
        when 'pid'        then pid
        when 'hostname'   then hostname
        when 'date'       then timestamp_str[ 0..7]
        when 'hour'       then timestamp_str[ 8..9]
        when 'min'        then timestamp_str[10..11]
        when 'sec'        then timestamp_str[12..13]
        when 'time'       then timestamp_str[ 8..13]
        else
          raise "Don't know how to encode pattern #{pattern}"
        end
      end

      def self.sanitize str
        str.gsub(%r{[^#{SAFE_CHARS}]+}, '-')
      end

      def expand pattern, timestamp_str
        pattern.gsub(/:\w+/){|token|
          token_val(token, timestamp_str)
        }
      end

      # Memoized: the hostname for the machine running this script.
      def hostname
        @hostname ||= ENV['HOSTNAME'] || `hostname`
      end
      # Memoized: the Process ID for this invocation.
      def pid
        @pid ||= Process.pid
      end
    end
  end
end
