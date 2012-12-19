%declare wukong_dir '/Users/flip/ics/core/wukong'
%declare data_dir   '$wukong_dir/data'
%declare dsfp_dir   '/Users/flip/ics/data_science_fun_pack'
;

register '$dsfp_dir/pig/varaha/target/varaha-1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/varaha/lib/mallet-2.0.7-RC2.jar';
register '$dsfp_dir/pig/varaha/lib/trove-2.0.4.jar';
register '$dsfp_dir/pig/varaha/lib/lucene-core-3.1.0.jar';
register '$dsfp_dir/pig/varaha/lib/pygmalion-1.1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/datafu/dist/datafu-0.0.6-SNAPSHOT.jar';

define JsonStrToString pigsy.pig.json.JsonStrToString();
define TokenizeText    varaha.text.TokenizeText();
define LDATopics       varaha.topic.LDATopics();
define RangeConcat     org.pygmalion.udf.RangeBasedStringConcat('0', ' ');

-- Load the markup-stripped wikipedia text
torture_strings = LOAD '$data_dir/helpers/torture/string_handling_test.tsv' AS (
  desc:chararray, len:int, bytesize:int, str:chararray, has_str:int, jsonized_str:chararray,
  escaped_chars:chararray, escaped_bytes:chararray, chars_list:chararray, bytes_list:chararray
  );

-- Generate a random integer between 0 and n
decoded = FOREACH torture_strings {
  unjsonized_str = JsonStrToString(jsonized_str);
  is_str_equal   = (((str == unjsonized_str) OR (has_str == 0)) ? 1 : 0);
  is_len_equal   = (  len == SIZE(unjsonized_str) ? 1 : 0  );
  GENERATE
    is_str_equal,
    is_len_equal,
    str AS str,
    unjsonized_str AS unjsonized_str
    ;
};

-- take a dump on your terminal window
DUMP decoded;
