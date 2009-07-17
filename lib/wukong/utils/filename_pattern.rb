module Wukong
  module Utils
    class FilenamePattern
      attr_accessor :pattern, :token_val_defaults
      def initialize pattern, token_val_defaults={}
        self.pattern = pattern
        self.token_val_defaults = token_val_defaults
      end

      #
      # walk through pattern, replacing tokens (eg :time or :pid) with the
      # corresponding value.
      #
      def make token_vals={}
        token_vals = token_vals.reverse_merge token_val_defaults
        token_vals[:timestamp] ||= Time.now.utc.to_flat
        val = pattern.gsub(/:(\w+)/){ replace($1, token_vals)  }
        val
      end

      #
      # substitute for token
      #
      def replace token, token_vals
        token = token.to_sym
        case token
        when :pid           then pid
        when :hostname      then hostname
        when :handle        then token_vals[:handle]
        when :handle_prefix then token_vals[:handle][0..5]
        when :datetime      then token_vals[:timestamp]
        when :date          then token_vals[:timestamp][ 0..7]
        when :time          then token_vals[:timestamp][ 8..13]
        when :hour          then token_vals[:timestamp][ 8..9]
        when :min           then token_vals[:timestamp][10..11]
        when :sec           then token_vals[:timestamp][12..13]
        else
          token_vals[token] or raise "Don't know how to encode token #{token} #{token_vals[token]}"
        end
      end

      # Memoized: the hostname for the machine running this script.
      def hostname
        @hostname ||= ENV['HOSTNAME'] || `hostname`
      end
      # Memoized: the Process ID for this invocation.
      def pid
        @pid      ||= Process.pid
      end

      # Characters deemed safe in a filename;
      SAFE_CHARS = 'a-zA-Z0-9_\-\.\+\/\;'
      def self.sanitize str
        str.gsub(%r{[^#{SAFE_CHARS}]+}, '-')
      end
    end
  end
end
