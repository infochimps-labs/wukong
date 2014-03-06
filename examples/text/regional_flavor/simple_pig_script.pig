%declare wukong_dir '/Users/flip/ics/core/wukong'
%declare data_dir   '$wukong_dir/data'
%declare dsfp_dir   '/Users/flip/ics/data_science_fun_pack'
;

register '$dsfp_dir/pig/datafu/dist/datafu-0.0.6-SNAPSHOT.jar';
register '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';

define RandInt         datafu.pig.numbers.RandInt();
define ConcatBag       com.infochimps.hadoop.pig.ConcatBag();

-- Load the data: the integers from 0 .. 1023
ones = LOAD '$data_dir/helpers/numbers/integers-1ki.tsv' AS (val:int);

-- Generate a random integer between 0 and n
rands        = FOREACH ones  GENERATE val, RandInt(0,val) AS rand_val;
rand_str_g   = GROUP rands ALL;
rand_str_s   = FOREACH rand_str_g  {
  joined_str = ConcatBag(rands.(rand_val));
  len        = SIZE(joined_str);
  GENERATE joined_str AS joined_str, len AS len;
};

-- take a dump on your terminal window
STORE rand_str_s INTO '/tmp/dump';

DESCRIBE rand_str_s;
