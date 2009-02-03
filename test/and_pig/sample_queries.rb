#!/usr/bin/env ruby
$: << File.dirname(__FILE__) + '/../..'
require 'wukong'
require 'wukong/and_pig' ; include Wukong::AndPig

HDFS_BASE_DIR = 'foo/meta/lang'
Wukong::AndPig::PigVar.working_dir = HDFS_BASE_DIR
Wukong::AndPig.comments    = false
Wukong::AndPig.emit_dest   = :captured

Wukong::AndPig::PigVar.emit 'REGISTER /usr/local/share/pig/contrib/piggybank/java/piggybank.jar'

#
# Load basic types
#

# class Token < Struct.new(:rsrc, :context, :user_id, :token, :usages)
# end
# :tokens_users_0 << Token.pig_load('meta/datanerds/token_count/users_tokens')
# :tokens_users_0 << Token.pig_load('/tmp/users_tokens.tsv')
# :tokens_users   << :tokens_users_0.generate(:user_id, :token, :usages)
# :tokens_users.checkpoint!

class Token < Struct.new(:user_id, :token, :usages)
end
:tokens_users << Token.pig_load('/tmp/users_tokens.tsv')
:tokens_users.describe

# pig_comment %Q{
# # ***************************************************************************
# #
# # Global totals
# #
# # Each row in Tokens lists a (user, token, usages)
# # We want
# #   Sum of all usage counts = total tokens seen in tweet stream.
# #   Number of distinct tokens
# #   Number of distinct users <- different than total in twitter_users.tsv
# #                               because we want only users that say stuff.
# }
#
# def count_distinct relation, field, options={}
#   result_name = options[:as] || "#{relation.name}_#{field}_count".to_sym
#   a = relation.
#     generate(field).set!.
#     distinct(options).set!
#   result_name << a.
#     group(:all).set!.
#     generate(["COUNT(#{a.relation}.#{field})", :u_count]).set!
# end
#
# pig_comment "Count Users"
# tok_users_count = count_distinct(:tokens_users, :user_id).checkpoint!
#
# pig_comment "Count Tokens"
# tok_tokens_count = count_distinct(:tokens_users, :token, :parallel => 10).checkpoint!


pig_comment %Q{
# ***************************************************************************
#
# Statistics for each user
}

def user_stats users_tokens
  users_tokens.
    group(   :by => :user_id).set!.
    generate(
      [:group, :user_id],
      ["(int)COUNT(#{users_tokens.relation})",                  :tot_tokens],
      [  "(int)SUM(#{users_tokens.relation}.usages)",           :tot_usages],
      [   "FLATTEN(#{users_tokens.relation}.(token, usages) )", [:token, :usages]]).set!.
    generate(:user_id, :token, :usages,
         ["(float)(1.0*usages / tot_usages)", :usage_pct],
         ["(float)(1.0*usages / tot_usages) * (1.0*(float)usages / tot_usages)", :usage_pct_sq]).set!
end

:user_stats << user_stats(:tokens_users)
:user_stats.checkpoint!
# puts "UserStats               = LOAD    'foo/meta/lang/user_stats' AS (user_id, token, usages, usage_pct, usage_pct_sq) ;"

UserStats = Struct.new(:user_id, :token, :usages, :usage_pct, :usage_pct_sq)
:user_stats << UserStats.pig_load('foo/meta/lang/user_stats')

def range_and_dispersion user_stats

  n_users  = 436
  n_tokens = 61630

  token_stats = user_stats.group(:token).set!
  token_stats = token_stats.foreach(
      ["(float)SUM(#{user_stats.relation}.usage_pct)    / #{n_users.to_f}",   :avg_uspct ],
    ["(float)SUM(#{user_stats.relation}.usage_pct_sq)",                     :sum_uspct_sq],
    ["org.apache.pig.piggybank.evaluation.math.SQRT(
                        (sum_uspct_sq /436) -
                        ( (SUM(#{user_stats.relation}.usage_pct)/436.0) * (SUM(#{user_stats.relation}.usage_pct)/436.0) )
                        )",     :stdev_uspct],
    ["1 - ( ( stdev_uspct / avg_uspct ) / org.apache.pig.piggybank.evaluation.math.SQRT(436.0 - 1.0) )",  :dispersion],
    [
      [:group,                                                     :token     ],
      ["(int)COUNT(#{user_stats.relation}) ",                                 :range     ],
      ["(int)COUNT(#{user_stats.relation})              / #{n_users.to_f}",   :pct_range ],
      ["(int)SUM(  #{user_stats.relation}.usages)",                           :tot_usages],
      ["(int)( 1e6 * SUM(#{user_stats.relation}.usages) / #{n_tokens.to_f})", :ppm_usages],
      [:avg_uspct,   :avg_uspct],
      [:stdev_uspct, :stdev_uspct],
      [:dispersion,  :dispersion]
    ]
    ).set!
end

range_and_dispersion(:user_stats).checkpoint!

Wukong::AndPig.finish
