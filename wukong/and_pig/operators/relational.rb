# -*- coding: utf-8 -*-
# == RelationalOperators
#
# GROUP, COGROUP, JOIN see groupies.rb
# CROSS see

# distinct
# filter
# limit
# order
# split
# union

#
# stream
# load
# store
#
module Wukong
  module AndPig
    class PigVar

      # ===========================================================================
      #
      # Options
      #
      def parallelize! str, options
        str << " PARALLEL #{options[:parallel]}" if options[:parallel]
      end

      # ===========================================================================
      #
      # CROSS
      #
      def cross options={}
        new_in_chain klass, "CROSS #{relation}"
      end

      # ===========================================================================
      #
      # DISTINCT
      #
      def distinct options={}
        new_in_chain klass, "DISTINCT #{relation}"
      end

      # ===========================================================================
      #
      # FILTER
      #
      def filter options={}
        new_in_chain klass, "FILTER #{relation}"
      end

      # ===========================================================================
      #
      # LIMIT
      #
      def limit options={}
        new_in_chain klass, "LIMIT #{relation}"
      end

      # ===========================================================================
      #
      # ORDER
      #
      def order options={}
        new_in_chain klass, "ORDER #{relation}"
      end

      # ===========================================================================
      #
      # SPLIT
      #
      # SPLIT alias INTO alias IF expression, alias IF expression [, alias IF expression …];
      #
      #
      def split options={}
        new_in_chain klass, "SPLIT #{relation}"
      end

      # ===========================================================================
      #
      # UNION
      #
      def self.union *relations
        new_in_chain klass, "UNION #{relation}"
      end

      # UNION as method
      def union *relations
        self.class.union self, *relations
      end

    end
  end
end
