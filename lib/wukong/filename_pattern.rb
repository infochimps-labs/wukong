module Wukong
    class FilenamePattern
      # the filename pattern, e.g. 'ripd/:handle/:date/:handle+:timestamp-:pid-:hostname.tsv'
      attr_accessor :pattern
      # custom token replacements
      attr_accessor :token_val_defaults

      DEFAULT_PATTERN_STR = ":dest_dir/:handle_prefix/:handle/:date/:handle:timestamp-:pid-:hostname.tsv"

      def initialize pattern, token_val_defaults={}
        self.pattern = pattern
        self.token_val_defaults    = token_val_defaults
      end

      #
      # walk through pattern, replacing tokens (eg :time or :pid) with the
      # corresponding value.
      #
      # Don't use ':' in a pattern except to introduce a token
      # and separate tokens with '-', '+' '/' or '.'
      #
      def make token_vals={}
        token_vals = token_val_defaults.merge token_vals
        token_vals[:timestamp] ||= Time.now.utc.strftime("%Y%m%d%H%M%S")
        val = pattern.gsub(/:(\w+)/){ replace($1, token_vals)  }
        val
      end

      def to_s token_vals={}
        make token_vals
      end

      #
      # substitute for token
      #
      def replace token, token_vals
        token = token.to_sym
        return token_vals[token] if token_vals.include? token
        case token
        when :pid           then pid
        when :hostname      then hostname
        when :handle        then token_vals[:handle]
        when :handle_prefix then token_vals[:handle].to_s[0..5]
        when :timestamp     then token_vals[:timestamp]
        when :date          then token_vals[:timestamp][ 0..7]
        when :time          then token_vals[:timestamp][ 8..13]
        when :hour          then token_vals[:timestamp][ 8..9]
        when :h4            then "%0.2d" % (( token_vals[:timestamp][8..9].to_i / 4 ) * 4)
        when :min           then token_vals[:timestamp][10..11]
        when :sec           then token_vals[:timestamp][12..13]
        when :s10           then "%0.2d" % (( token_vals[:timestamp][12..13].to_i / 10 ) * 10)
        else
          raise "Don't know how to encode token #{token} #{token_vals[token]}"
        end
      end

      # Memoized: the hostname for the machine running this script.
      def hostname
        @hostname ||= ENV['HOSTNAME'] || `hostname`.chomp
      end
      # Memoized: the Process ID for this invocation.
      def pid
        @pid      ||= Process.pid
      end

      # Characters deemed safe in a filename;
      SAFE_CHARS = 'a-zA-Z0-9_\-\.\+\/'
      RE_SAFE_FILENAME = %r{[^#{SAFE_CHARS}]+}moxi
      def self.sanitize str
        str.gsub(RE_SAFE_FILENAME, '-')
      end

    end
end
