# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wukong}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer"]
  s.date = %q{2009-04-08}
  s.description = %q{Treat your dataset like a:  * stream of lines when it’s efficient to process by lines * stream of field arrays when it’s efficient to deal directly with fields * stream of lightweight objects when it’s efficient to deal with objects  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.}
  s.email = %q{flip@infochimps.org}
  s.executables = ["cutc", "cuttab", "hdp-cat", "hdp-catd", "hdp-du", "hdp-get", "hdp-kill", "hdp-ls", "hdp-mkdir", "hdp-mv", "hdp-parts_to_keys.rb", "hdp-ps", "hdp-put", "hdp-rm", "hdp-sort", "hdp-stream", "hdp-stream-flat", "hdp-sync"]
  s.extra_rdoc_files = ["README-tutorial.textile", "README.textile", "LICENSE.txt"]
  s.files = ["wukong.gemspec", "config/wukong.yaml", "doc/PigLatinExpressionsList.txt", "doc/PigLatinReferenceManual.html", "doc/PigLatinReferenceManual.txt", "examples/and_pig", "examples/and_pig/sample_queries.rb", "examples/count_keys.rb", "examples/count_keys_at_mapper.rb", "examples/graph", "examples/graph/gen_2paths.rb", "examples/graph/gen_multi_edge.rb", "examples/graph/gen_symmetric_links.rb", "examples/package-local.rb", "examples/package.rb", "examples/pagerank", "examples/pagerank/gen_initial_pagerank_graph.pig", "examples/pagerank/pagerank.rb", "examples/pagerank/pagerank_initialize.rb", "examples/rank_and_bin.rb", "examples/run_all.sh", "examples/sample_records.rb", "examples/size.rb", "examples/word_count.rb", "spec/spec_helper.rb", "lib/wukong", "lib/wukong/and_pig", "lib/wukong/and_pig/README.textile", "lib/wukong/and_pig/as.rb", "lib/wukong/and_pig/data_types.rb", "lib/wukong/and_pig/functions.rb", "lib/wukong/and_pig/generate", "lib/wukong/and_pig/generate/variable_inflections.rb", "lib/wukong/and_pig/generate.rb", "lib/wukong/and_pig/junk.rb", "lib/wukong/and_pig/operators", "lib/wukong/and_pig/operators/compound.rb", "lib/wukong/and_pig/operators/evaluators.rb", "lib/wukong/and_pig/operators/execution.rb", "lib/wukong/and_pig/operators/file_methods.rb", "lib/wukong/and_pig/operators/foreach.rb", "lib/wukong/and_pig/operators/groupies.rb", "lib/wukong/and_pig/operators/load_store.rb", "lib/wukong/and_pig/operators/meta.rb", "lib/wukong/and_pig/operators/relational.rb", "lib/wukong/and_pig/operators.rb", "lib/wukong/and_pig/pig_struct.rb", "lib/wukong/and_pig/pig_var.rb", "lib/wukong/and_pig/symbol.rb", "lib/wukong/and_pig/utils.rb", "lib/wukong/and_pig.rb", "lib/wukong/boot.rb", "lib/wukong/datatypes", "lib/wukong/datatypes/enum.rb", "lib/wukong/dfs.rb", "lib/wukong/encoding.rb", "lib/wukong/extensions", "lib/wukong/extensions/array.rb", "lib/wukong/extensions/date_time.rb", "lib/wukong/extensions/emittable.rb", "lib/wukong/extensions/hash.rb", "lib/wukong/extensions/string.rb", "lib/wukong/extensions/struct.rb", "lib/wukong/extensions/symbol.rb", "lib/wukong/extensions.rb", "lib/wukong/models", "lib/wukong/models/graph.rb", "lib/wukong/script", "lib/wukong/script/hadoop_command.rb", "lib/wukong/script/local_command.rb", "lib/wukong/script.rb", "lib/wukong/streamer", "lib/wukong/streamer/accumulating_reducer.rb", "lib/wukong/streamer/base.rb", "lib/wukong/streamer/count_keys.rb", "lib/wukong/streamer/count_lines.rb", "lib/wukong/streamer/filter.rb", "lib/wukong/streamer/line_streamer.rb", "lib/wukong/streamer/list_reducer.rb", "lib/wukong/streamer/preprocess_with_pipe_streamer.rb", "lib/wukong/streamer/rank_and_bin_reducer.rb", "lib/wukong/streamer/set_reducer.rb", "lib/wukong/streamer/struct_streamer.rb", "lib/wukong/streamer/uniq_by_last_reducer.rb", "lib/wukong/streamer.rb", "lib/wukong/typed_struct.rb", "lib/wukong.rb", "bin/cutc", "bin/cuttab", "bin/hdp-cat", "bin/hdp-catd", "bin/hdp-du", "bin/hdp-get", "bin/hdp-kill", "bin/hdp-ls", "bin/hdp-mkdir", "bin/hdp-mv", "bin/hdp-parts_to_keys.rb", "bin/hdp-ps", "bin/hdp-put", "bin/hdp-rm", "bin/hdp-sort", "bin/hdp-stream", "bin/hdp-stream-flat", "bin/hdp-sync", "README-tutorial.textile", "README.textile", "LICENSE.txt"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mrflip/wukong}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Wukong makes Hadoop so easy a chimpanzee can use it.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
