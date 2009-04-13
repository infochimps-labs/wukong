#!/usr/bin/env bash

# Directory to pagerank on.
work_dir=$1 ; shift
if [ "$work_dir" == '' ] ; then echo "Please specify the parent of the directory made by gen_initial_pagerank" ; exit ; fi


# How many rounds to run
max_iter=10
# this directory
script_dir="`dirname $0`"

for (( curr=0 , next=1 ; "$curr" < "$max_iter" ; curr++ , next++ )) ; do
  curr_str=`printf "%03d" ${curr}`
  next_str=`printf "%03d" ${next}`
  curr_dir=$work_dir/pagerank_graph_${curr_str}
  next_dir=$work_dir/pagerank_graph_${next_str}
  $script_dir/pagerank.rb --rm --run $curr_dir $next_dir
done
