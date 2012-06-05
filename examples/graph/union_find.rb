module Wukong::Widget

  # Implements a disjoint-set data structure:
  #
  # @see http://en.wikipedia.org/wiki/Union-find
  #
  class DisjointForest
    # Tree each node belongs to
    attr_reader :parent
    # Depth of node in that tree
    attr_reader :rank

    def initialize
      @parent = {}
      @rank   = {}
    end

    def add(val)
      parent[val] = val
      rank[val]   = 0
    end
    alias_method :<<, :add

    #
    # Returns the root (the identifying member) of the set that the given value
    # belongs to.
    #
    def find(val)
      return val if root?(val)
      parent[val] = find parent[val]
    end
    alias_method :[], :find

    def union(val_a, val_b)
      add(val_a) if !include?(val_a)
      add(val_b) if !include?(val_b)
      root_a = find(val_a)
      root_b = find(val_b)
      return if root_a == root_b
      # a and b are in different sets; merge the smaller to the larger
      Log.debug("Merging #{val_a} (root #{root_a} depth #{rank[root_a]} and #{val_b} (root #{root_b} depth #{rank[root_b]})")
      if    rank[root_a] < rank[root_b]
        parent[root_a] = root_b
      elsif rank[root_a] > rank[root_b]
        parent[root_b] = root_a
      else
        parent[root_a] = root_b
        rank[root_b] += 1
      end
    end
    alias_method :merge, :union

    def root?(val)
      parent[val] == val
    end

    def include?(val)
      parent.include?(val)
    end

  end
end
