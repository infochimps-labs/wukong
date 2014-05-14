# encoding:UTF-8

module Wu
  module Text
    module EncodingCleaner
      extend self

      REPLACEMENT_CHAR = "\uFFFD" # that funny <?>-looking character

      # Replaces all malformed characters in the
      # input stream with a "?".
      def clean_encoding(line)
        # Log.debug([line.encoding.name, line])
        line.each_char.map do |char|
          char.valid_encoding? ? char : REPLACEMENT_CHAR
        end.join
      end

      def each_safely(source, &block)
        source.each do |line|
          if not line.valid_encoding?
            line = clean_encoding(line)
          end
          block.call(line)
        end
      end

    end
  end
end
