# -*- coding: utf-8 -*-
#
# The FOREACH relational operator
#
module Wukong
  module AndPig
    class PigVar

      #===========================================================================
      #
      # GROUP and COGROUP
      #

      #
      # COGROUP - Groups the data in two or more relations.
      #
      # == Syntax
      #
      #   alias  = COGROUP alias1 BY field_alias [INNER | OUTER],
      #                    aliasN BY field_alias [INNER | OUTER] [PARALLEL n] ;
      #
      # == Structure
      #
      #   { group, <structure of alias1>, <structure of alias2>, ... }
      #
      # == Terms
      #
      # * alias         The name a relation.
      #
      # * field_alias The name of one or more fields in a relation.  If multiple
      #                 fields are specified, separate with commas and enclose
      #                 in parentheses. For example, X = COGROUP A BY (f1, f2);
      #
      #                 The number of fields specified in each BY clause must
      #                 match. For example, X = COGROUP A BY (a1,a2,a3), B BY
      #                 (b1,b2,b3);
      #
      # * BY            Keyword.
      #
      # * INNER         Eliminate NULLs on that grouping
      # * OUTER         Do not eliminate NULLs on that grouping (default)
      #
      # * PARALLEL n -- Increase the parallelism of a job by specifying the
      #                 number of reduce tasks, n. The optimal number of
      #                 parallel tasks depends on the amount of memory on each
      #                 node and the memory required by each of the tasks. To
      #                 determine n, use the following as a general guideline:
      #
      #                     n = (nr_nodes - 1) * 0.45 * nr_GB
      #
      #                 where nr_nodes is the number of nodes used and nr_GB is
      #                 the amount of physical memory on each node.
      #
      #                 Note the following:
      #                 - Parallel only affects the number of reduce tasks. Map
      #                   parallelism is determined by the input file, one map
      #                   for each HDFS block.
      #                 - If you don’t specify parallel, you still get the same
      #                   map parallelism but only one reduce task.
      #
      # == Usage
      #
      # The COGOUP operator groups the data in two or more relations based on
      # the common field values.
      #
      # Note: The COGROUP and JOIN operators perform similar functions. COGROUP
      # creates a nested set of output tuples while JOIN creates a flat set of
      # output tuples with NULLs eliminated.
      #
      # == Examples
      #
      # Suppose we have two relations, A and B.
      #
      # A: (owner:chararray, pet:chararray)
      # ---------------
      # (Alice, cat)
      # (Alice, goldfish)
      # (Alice, turtle)
      # (Bob,   cat)
      # (Bob,   dog)
      #
      # B: (friend1:chararray, friend2:charrarray)
      # ---------------------
      # (Cindy, Alice)
      # (Mark, Alice)
      # (Paul, Bob)
      # (Paul, Jane)
      #
      # In this example tuples are co-grouped using field “owner” from relation
      # A and field “friend2” from relation B as the key fields. The DESCRIBE
      # operator shows the schema for relation X, which has two fields, "group"
      # and "A" (for an explanation, see GROUP).
      #
      #   X = COGROUP A BY owner, B BY friend2;
      #   DESCRIBE X;
      #
      #    X: {group: chararray,
      #        A: {owner:   chararray,pet:     chararray},
      #        B: {friend1: chararray,friend2: chararray}}
      #
      # Relation X looks like this. A tuple is created for each unique key
      # field. The tuple includes the key field and two bags. The first bag is
      # the tuples from the first relation with the matching key field. The
      # second bag is the tuples from the second relation with the matching key
      # field. If no tuples match the key field, the bag is empty.
      #
      #   (Alice, {(Alice, turtle), (Alice, goldfish), (Alice, cat)},
      #           {(Cindy, Alice), (Mark, Alice)})
      #   (Bob,   {(Bob, dog), (Bob, cat)},
      #           {(Paul, Bob)})
      #   (Jane,  {},
      #           {(Paul, Jane)})
      #
      # In this example tuples are co-grouped and the INNER keyword is used to
      # ensure that only bags with at least one tuple are returned.
      #
      #   X = COGROUP A BY owner INNER, B BY friend2 INNER;
      #
      # Relation X looks like this.
      #
      #   (Alice, {(Alice, turtle), (Alice, goldfish), (Alice, cat)},
      #           {(Cindy, Alice), (Mark, Alice)})
      #   (Bob,   {(Bob, dog), (Bob, cat)},
      #           {(Paul, Bob)})
      #
      # In this example tuples are co-grouped and the INNER keyword is used
      # asymmetrically on only one of the relations.
      #
      #   X = COGROUP A BY owner, B BY friend2 INNER;
      #
      # Relation X looks like this.
      #
      #   (Alice, {(Alice, turtle), (Alice, goldfish), (Alice, cat)},
      #           {(Cindy, Alice), (Mark, Alice)})
      #   (Bob,   {(Bob, dog), (Bob, cat)},
      #           {(Paul, Bob)})
      #   (Jane,  {},
      #           {(Paul, Jane)})
      #
      #
      def group group_by
        l_klass   = l_klass_for_group group_by
        by_clause = self.class.make_by_clause(group_by)
        new_in_chain anon, l_klass, "GROUP    #{relation} #{by_clause}"
      end

      def self.make_by_clause by_spec
        case by_spec
        when Array      then 'BY ' + by_spec.join(", ")
        when :all       then 'ALL'
        when Symbol     then "BY #{by_spec}"
        when String     then by_spec
        when Hash       then make_by_clause(by_spec[:by])
        else raise "Don't know how to group on #{by_spec.inspect}"
        end
      end
      def types_for_fields field
        klass.members_types[field]
      end
      def l_klass_for_group group_by
        self.class.l_klass_for_group group_by, self
      end
      def self.l_klass_for_group group_by, *rels
        TypedStruct.new(
          [:group,       rels.first.types_for_fields(group_by)],
          *rels.map{|rel| [rel.relation, rel.klass] }
          )
      end

      #
      # COGROUP pig expression:
      #   UserPosts = COGROUP Posts BY user_id, Users BY user_id ;
      #
      def self.cogroup lval, *by
        by_clause = by.map do |relation, group_by, as|
          "%s %s" % [relation.relation, make_by_clause(group_by)]
        end.join(", ")
        l_klass  = l_klass_for_group by[0][1], *by.map(&:first)
        rval = new l_klass, lval, "COGROUP    #{by_clause}"
        set lval, rval
      end

      def cogroup *args
        self.class.cogroup self, *args
      end


      # ===========================================================================
      #
      # JOIN
      #
      def self.klass_from_join by
        klasses = by.map(&:first)
        TypedStruct.new(*klasses.zip(klasses.map(&:klass)))
      end

      def self.join_by_clause by
        by.map{|rel, field| "#{rel.relationize} BY #{field}" }.join(", ")
      end

      def self.join lval, by
        parallel = by.delete(:parallel)
        cmd  = "JOIN " + join_by_clause(by)
        parallelize! cmd, :parallel => parallel
        l_klass = klass_from_join(by)
        rval = new(l_klass, lval, cmd)
        set lval, rval
      end

    end
  end
end
