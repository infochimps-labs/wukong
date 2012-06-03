module Wukong::Widget

  # Implements a disjoint-set data structure:
  #
  # @see http://en.wikipedia.org/wiki/Union-find
  #
  class UnionFind
    # Tree each node belongs to
    attr_reader :parents
    # Depth of node in that tree
    attr_reader :ranks

    def initialize
      @parents = {}
      @ranks   = {}
    end

    def add(val)
      parents[val] = val
      ranks[val]   = 0
    end
    def <<(val) ; add(val) ; end

    def find(val)
      return val if root?(val)
      find parents[val]
    end
    def [](val) ; find(val) ; end

    def root?(val)
      parents[val] == val
    end

    def union(val_a, val_b)
      root_a = find(val_a)
      root_b = find(val_b)
      parents[root_a] = root_b
      root_b
    end
  end
end
