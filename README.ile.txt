

== How to run a Wukong script

  ./path/to/your/script.rb --any_specific_options --options=can_have_vals --go input_file1.tsv,input_file2.tsv,etc.tsv path/to/output_dir

All of the file paths are HDFS paths ; your script path, of course, is on the local filesystem.


== How to test your scripts

To run mapper on its own:
  cat ./local/test/input.tsv | ./examples/word_count.rb --map | more
or if your test data lies on the HDFS,
  hdp-cat test/input.tsv | ./examples/word_count.rb --map | more
