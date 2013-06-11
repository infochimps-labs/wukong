module Wukong
  class Processor

    # Joins XML input data based on a root tag.
    class JoinXML < Processor

      field :root, String, default: 'xml', doc: "Name of the root XML element"

      def setup
        @lines = []
      end

      def process line
        if match = terminator.match(line)
          if match.end(0) == line.size
            @lines << line
          else
            @lines << line[0...match.end(0)]
          end
          yield @lines.join("\n")
          @lines = []
          @lines << line[match.end(0)..-1] unless match.end(0) == line.size
        else
          @lines << line
        end
      end
    
      def terminator
        %r{<\s*/\s*#{root}\s*>}i
      end
      
      register :join_xml
    end
  end
end


