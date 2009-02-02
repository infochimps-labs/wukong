

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

  end
end
