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
      def self.parallelize! str, options
        str << " PARALLEL #{options[:parallel]}" if options[:parallel]
      end

      # ===========================================================================
      #
      # DISTINCT
      #
      def distinct lval, options={}
        self.class.distinct lval, self, options
      end

      def self.distinct lval, rel, options={ }
        cmd_str = rel.relationize
        parallelize! cmd_str, options
        simple_operation lval, rel, :distinct, cmd_str
      end

      # ===========================================================================
      #
      # FILTER
      #
      def filter by_str
        new_in_chain klass, "FILTER   #{relation} BY #{by_str}"
      end
      def self.filter lval, rel, by_str
        simple_operation    lval, rel, "FILTER", "#{rel.relation} BY #{by_str}"
      end

      # ===========================================================================
      #
      # LIMIT
      #
      def limit n
        new_in_chain klass, "LIMIT   #{relation} #{n}"
      end

      # ===========================================================================
      #
      # ORDER
      #
      # alias = ORDER alias BY { * [ASC|DESC] |
      #           field_alias [ASC|DESC] [, field_alias [ASC|DESC] …]
      #           } [PARALLEL n];
      #
      def order cmd_str, options={}
        result = new_in_chain klass, "ORDER    #{relation} BY #{cmd_str}"
        parallelize! result.cmd, options
        result
      end

      # ===========================================================================
      #
      # SPLIT
      #
      # SPLIT alias INTO alias IF expression, alias IF expression [, alias IF expression …];
      #
      #
      def split relation_tests={}
        split_str = relation_tests.map do |out_rel, test|
          "#{out_rel} IF #{test}"
        end.join(", ")
        new_in_chain klass, "SPLIT    #{relation} INTO #{split_str}"
      end

      # ===========================================================================
      #
      # CROSS
      #
      def cross *relations
        options = relations.extract_options!
        raise CrossArgumentError unless relations.length >= 1
        relations_str = [self, *relations].map(&:relation).join(", ")
        result = new_in_chain relations.first.klass, "CROSS    #{relations_str}"
        parallelize! result.cmd, options
        result
      end

      # ===========================================================================
      #
      # UNION
      #
      # def self.union *relations
      #   raise UnionArgumentError unless relations.length >= 2
      #   new_in_chain relations.first.klass, "UNION #{relations}"
      # end

      # UNION as method
      def union lval, *relations
        self.class.union lval, [self]+relations
      end

      def self.union lval, *relations
        raise UnionArgumentError unless relations.length >= 2
        relations_str = relations.map(&:relation).join(", ")
        simple_operation lval, relations.first, :union, relations_str
      end

    end
    CrossArgumentError = ArgumentError.new("CROSS requires at least two relations. Heh heh: relations.")
    UnionArgumentError = ArgumentError.new("UNION requires at least two relations. Heh heh: relations.")
  end
end
