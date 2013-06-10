module Wukong
  class Processor

    # Joins XML input data based on a root tag.
    class JoinXML < Processor

      field :root, String, default: 'xml', doc: "Name of the root XML element"

      def setup
        @lines = []
      end

      def process line
        @lines << line
        if terminates_document?(line)
          yield @lines.join("\n")
          @lines = []
        end
      end
      
      def terminates_document?(line)
        line =~ %r{<\s*/\s*#{root}\s*>}i
      end
      
      def starts_document?(line)
        line =~ %r{<\s*#{root}\s*>}i
      end

      register :join_xml
    end
  end
end
