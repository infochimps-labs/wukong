#!/usr/bin/env ruby
$: << File.dirname(__FILE__) + '/../..'
require 'wukong'         ; include Wukong
require 'wukong/and_pig' ; include Wukong::AndPig

# PIG_DIR = '/usr/local/share/pig'
PIG_DIR = '/public/share/pig'
# full pathname to the pig executable
# Wukong::AndPig::PIG_EXECUTABLE = "#{PIG_DIR}/bin/pig"
Wukong::AndPig::PIG_EXECUTABLE = "/public/bin/pig -x local"

#
HDFS_BASE_DIR = 'foo/meta/lang'
Wukong::AndPig::PigVar.working_dir = HDFS_BASE_DIR
Wukong::AndPig.comments    = false
# Wukong::AndPig.emit_dest   = :captured

Wukong::AndPig::PigVar.emit "REGISTER #{PIG_DIR}/contrib/piggybank/java/piggybank.jar"

#
# Load basic types
#

# class Token < Struct.new(:rsrc, :context, :user_id, :token, :usages)
# end
# :tokens_users_0 << Token.pig_load('meta/datanerds/token_count/users_tokens')
# :tokens_users_0 << Token.pig_load('/tmp/users_tokens.tsv')
# :tokens_users   << :tokens_users_0.generate(:user_id, :token, :usages)
# :tokens_users.checkpoint!

class Token < TypedStruct.new(
      [:user_id, Integer], [:token, String], [:usages, Integer])
end
:tokens_users << Token.pig_load('/tmp/users_tokens.tsv')
:tokens_users.describe

pig_comment %Q{
# ***************************************************************************
#
# Global totals
#
# Each row in Tokens lists a (user, token, usages)
# We want
#   Sum of all usage counts = total tokens seen in tweet stream.
#   Number of distinct tokens
#   Number of distinct users <- different than total in twitter_users.tsv
#                               because we want only users that say stuff.
}

def count_distinct relation, field, options={}
  result_name = options[:as] || "#{relation.name}_#{field}_count".to_sym
  a = relation.
    generate(field).set!.describe.
    distinct(options).set!
  result_name << a.
    group(:all).set!.
    generate(["COUNT(#{a.relation}.#{field})", :u_count, Integer]).set!
end

pig_comment "Count Users"
tok_users_count = count_distinct(:tokens_users, :user_id).checkpoint!

pig_comment "Count Tokens"
tok_tokens_count = count_distinct(:tokens_users, :token, :parallel => 10).checkpoint!


pig_comment %Q{
# ***************************************************************************
#
# Statistics for each user
}

def user_stats users_tokens
  users_tokens.describe.
    group(   :user_id).set!.describe.
    generate(
      [:group, :user_id],
      ["(int)COUNT(#{users_tokens.relation})",          :tot_tokens, Integer],
      [  "(int)SUM(#{users_tokens.relation}.usages)",   :tot_usages, Integer],
      [   "FLATTEN(#{users_tokens.relation}.token",     :token,      String ],
      [   "FLATTEN(#{users_tokens.relation}.usages",    :usages,     Integer]).set!.describe.
    # [   "FLATTEN(#{users_tokens.relation}.(token, usages) )", [:token, :usages], TypedStruct.new([:token, String], [:usages, Integer])]).set!.
    generate(:user_id, :token, :usages,
         ["(float)(1.0*usages / tot_usages)", :usage_pct, Float],
         ["(float)(1.0*usages / tot_usages) * (1.0*(float)usages / tot_usages)", :usage_pct_sq, Float]).set!
end

:user_stats << user_stats(:tokens_users)
:user_stats.describe.checkpoint!
puts "UserStats               = LOAD    'foo/meta/lang/user_stats' AS (user_id, token, usages, usage_pct, usage_pct_sq) ;"

UserStats = TypedStruct.new([:user_id, Integer],
  [:token, String],
  [:usages, Integer],
  [:usage_pct, Float],
  [:usage_pct_sq, Float])
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
      [:group,                                                                :token,     String     ],
      ["(int)COUNT(#{user_stats.relation}) ",                                 :range,     Integer     ],
      ["(int)COUNT(#{user_stats.relation})              / #{n_users.to_f}",   :pct_range,  Integer ],
      ["(int)SUM(  #{user_stats.relation}.usages)",                           :tot_usages, Integer],
      ["(float)( 1.0e6*SUM(#{user_stats.relation}.usages) / #{n_tokens.to_f})", :ppm_usages, Float],
      [:avg_uspct,   :avg_uspct],
      [:stdev_uspct, :stdev_uspct],
      [:dispersion,  :dispersion]
    ]
    ).set!
end

range_and_dispersion(:user_stats).checkpoint!

Wukong::AndPig.finish
