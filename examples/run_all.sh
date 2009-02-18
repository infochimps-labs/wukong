#!/usr/bin/env bash

src_path="tmp/README.textile"
out_root="tmp/test"
hdp_opts="--map_tasks=1 --reduce_tasks=1"

# ---------------------------------------------------------------------------
#
# Set up directories and copy over sample input
#

# hdp-rm ${src_path}
# hdp-put `dirname $0`/../README.textile tmp/
# hdp-mkdir $out_root 

# ---------------------------------------------------------------------------
#
# Run scripts
#

cmd="word_count"
    # hdp-rm -r ${out_root}/${cmd}
    # ./examples/${cmd}.rb  	--run $hdp_opts $src_path ${out_root}/${cmd}
    # hdp-catd ${out_root}/${cmd} | head -n 20
    word_count=${out_root}/${cmd}

cmd="sample_records"
    # hdp-rm -r ${out_root}/${cmd}
    # ./examples/${cmd}.rb  	--sampling_fraction=0.8 \
    #     			--run $hdp_opts $src_path ${out_root}/${cmd}
    # hdp-catd ${out_root}/${cmd} | head -n 200 | tail -n 20
    sample_records=${out_root}/${cmd}


# cmd="size"
#     hdp-rm -r ${out_root}/${cmd}
#     ./examples/${cmd}.rb  	--run $hdp_opts $src_path ${out_root}/${cmd}
#     hdp-catd ${out_root}/${cmd} 
#     size=${out_root}/${cmd}


cmd="count_keys"
    hdp-rm -r ${out_root}/${cmd}
    ./examples/${cmd}.rb  	--run $hdp_opts $word_count ${out_root}/${cmd}
    hdp-catd ${out_root}/${cmd}  | head -n 200 | tail -n 20
    count_keys=${out_root}/${cmd}

