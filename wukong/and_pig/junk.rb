

module Wukong
  module AndPig

    #
    # Load the main class definitions
    #
    def self.init_load
      puts File.open(PIG_DEFS_DIR+"/init_load.pig").read
    end

    class AS
      def self.[] klass
        klass.as
      end
    end



    #
    # OK we're going to cheat here:
    # just cat the file in, and treat it as a scalar
    #
    def load_scalar path
      # var = `hadoop dfs -cat '#{path}/part-*' | head -n1 `.chomp
      var = "636"
    end



    def count_distinct dest_rel, attr, group_by
      distincted =
        generate(temp_rel(dest_rel), attr).
        distinct(temp_rel(dest_rel), :parallel => 10)
      distincted.
        group(   temp_rel(dest_rel), group_by).
        foreach( dest_rel,  "GENERATE COUNT(#{distincted.relation}.#{attr}) AS n_#{attr}")
    end

    #
    # Group a relation into bins, and return the counts for each bin
    # * dest_rel - Relation to store
    #   {bin,
    #
    def histogram dest_rel, bin_attr, bin_expr=nil
      bin_expr ||= bin_attr
      bin_name   = "#{bin_attr}_bin"
      binned     = foreach(temp_rel(dest_rel), "GENERATE #{bin_expr} AS #{bin_name}")
      binned.      group(  temp_rel(dest_rel), :by => bin_name).
        foreach(         dest_rel,  "GENERATE group AS #{bin_name}, COUNT(#{binned.relation}) AS #{bin_attr}_count")
    end


  end
end
