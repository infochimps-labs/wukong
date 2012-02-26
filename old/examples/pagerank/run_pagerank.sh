#!/usr/bin/env bash

# Directory to pagerank on.
work_dir=$1     ; shift
if [ "$work_dir" == '' ] ; then echo "Please specify the parent of the directory made by gen_initial_pagerank: $0 initial_dir [number_of_iterations] [start_iteration]" ; exit ; fi
# How many rounds to run: default 10
n_iters=${1-10} ; shift
# the iteration to start with: default 0
start_i=${1-0}  ; shift

# this directory
script_dir="`dirname $0`"

for (( iter=0 ; "$iter" < "$n_iters" ; iter++ )) ; do
  curr_str=`printf "%03d" $(( $start_i + $iter     ))`
  next_str=`printf "%03d" $(( $start_i + $iter + 1 ))`
  curr_dir=$work_dir/pagerank_graph_${curr_str}
  next_dir=$work_dir/pagerank_graph_${next_str}
  echo -e "Iteration $(( $iter + 1 )) / $n_iters:\t `basename $curr_dir` => `basename $next_dir`"
  $script_dir/pagerank.rb --rm --run $curr_dir $next_dir
done
