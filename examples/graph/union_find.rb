module Wukong::Widget

  # Implements a disjoint-set data structure:
  #
  # @see http://en.wikipedia.org/wiki/Union-find
  #
  class DisjointForest
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
    alias_method :<<, :add

    def find(val)
      add(val)   if !include?(val)
      return val if root?(val)
      parents[val] = find parents[val]
    end
    alias_method :[], :find

    def root?(val)
      parents[val] == val
    end

    def include?(val)
      parents.include?(val)
    end

    def union(val_a, val_b)
      root_a = find(val_a)
      root_b = find(val_b)
      return if root_a == root_b
      # a and b are in different sets; merge the smaller to the larger
      if    ranks[root_a] < ranks[root_b]
        parents[root_a] = root_b
      elsif ranks[root_a] > ranks[root_b]
        parents[root_b] = root_a
      else
        parents[root_b] = root_a
        ranks[root_a] += 1
      end
    end
    alias_method :merge, :union

  end
end
