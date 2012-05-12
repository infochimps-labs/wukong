module Hanuman
  module Executor


  end

  class Flow
    module ToGraphviz
      def to_graphviz(builder, options={})
      end
    end
    include ToGraphviz
  end

  class Stage
    module ToGraphviz
      def to_graphviz(options={})

      end
    end
    include ToGraphviz
  end

  class Chain
    module ToGraphviz
      def to_graphviz(options={})

      end
    end
    include ToGraphviz
  end


end
