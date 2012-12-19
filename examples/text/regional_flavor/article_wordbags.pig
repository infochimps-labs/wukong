%declare dsfp_dir         '/home/flip/ics/data_science_fun_pack'
%declare wukong_dir       '/home/flip/ics/core/wukong_ng'
%declare data_dir         '/data'
-- %declare wp_data          '$data_dir/results/wikipedia/full'
%declare wp_data       '$data_dir/results/wikipedia/mini'
;
%declare article_texts    '$wp_data/article_texts.tsv'
%declare article_wordbags '$wp_data/article_wordbags.tsv'
-- %declare geolocations     '$wp_data/geolocations.tsv'
%declare geolocations     '/data/results/dbpedia/full/dbpedia_geolocations.tsv'
%declare geo_wordbags     '$wp_data/geo_wordbags.tsv'
;

register '$dsfp_dir/pig/varaha/target/varaha-1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/varaha/lib/mallet-2.0.7-RC2.jar';
register '$dsfp_dir/pig/varaha/lib/trove-2.0.4.jar';
register '$dsfp_dir/pig/varaha/lib/lucene-core-3.1.0.jar';
register '$dsfp_dir/pig/varaha/lib/pygmalion-1.1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';
register '$dsfp_dir/pig/datafu/dist/datafu-0.0.6-SNAPSHOT.jar';

define TokenizeText    varaha.text.TokenizeText();
define WordbagizeText  pigsy.text.WordbagizeText();
define JsonStrToString pigsy.json.JsonStrToString();

-- Load the markup-stripped wikipedia text
article_texts_all = LOAD '$article_texts' AS (
  page_id:long, namespace:int, wikipedia_id:chararray,
  revision_id:long, timestamp:chararray,
  title:chararray, redirect:chararray,
  raw_text:chararray);

-- Remove redirects
article_texts = FILTER article_texts_all BY (redirect IS NULL);

-- Generate the wordbag
article_wordbags_0 = FOREACH article_texts  {
  unraw_text   = JsonStrToString(raw_text);
  words        = TokenizeText(unraw_text);
  wb           = WordbagizeText(words);
  GENERATE
    page_id, namespace, wikipedia_id,
    wb.$0 AS tot_usages:int,
    wb.$1 AS num_terms:int,
    wb.$2 AS num_onces:int,
    wb.$3 AS wordbag:{T:(count:int,term:chararray)}
  ;
};

-- Sort the wordbag by frequency (most common first) and then by word
article_wordbags = FOREACH article_wordbags_0 {
  wordbag_s = ORDER wordbag BY count DESC, term ASC;
  GENERATE
    page_id, namespace, wikipedia_id,
    tot_usages AS tot_usages,
    num_terms  AS num_terms,
    num_onces  AS num_onces,
    wordbag_s  AS wordbag:{T:(count:int,term:chararray)}
    ;
};

-- -- DESCRIBE article_wordbags;
-- rmf                          $article_wordbags
-- STORE article_wordbags INTO '$article_wordbags';

-- Run from stored copy
article_wordbags = LOAD  '$article_wordbags' AS (
  page_id:long, namespace:int, wikipedia_id:chararray,
  tot_usages:int,
  num_terms:int,
  num_onces:int,
  wordbag:{T:(count:int,term:chararray)}
  );

geolocations = LOAD '$geolocations' AS (
  page_id:long, namespace:int, wikipedia_id:chararray,
  longitude:float, latitude:float, quadkey:chararray
  );

-- Mini-me

-- article_wordbags_mini = FILTER article_wordbags BY (tot_usages > 1000) AND (wikipedia_id MATCHES '^A.*');
-- rmf                               /data/results/wikipedia/mini/article_wordbags.tsv
-- STORE article_wordbags_mini INTO '/data/results/wikipedia/mini/article_wordbags.tsv';

-- geolocations_mini    = FILTER geolocations BY (wikipedia_id MATCHES '^A.*');
-- rmf                               /data/results/wikipedia/mini/geolocations.tsv
-- STORE geolocations_mini     INTO '/data/results/wikipedia/mini/geolocations.tsv';

geo_wordbags_0 = JOIN
  geolocations     BY wikipedia_id,
  article_wordbags BY wikipedia_id
  PARALLEL 15
  ;

geo_wordbags = FOREACH geo_wordbags_0 GENERATE
  geolocations::page_id, geolocations::namespace, geolocations::wikipedia_id,
  geolocations::longitude, geolocations::latitude, geolocations::quadkey,
  tot_usages,
  num_terms,
  num_onces,
  -- wordbag AS wordbag:{T:(count:int,term:chararray)}
  wordbag
  ;

DESCRIBE geo_wordbags;
rmf                      $geo_wordbags
STORE geo_wordbags INTO '$geo_wordbags';
