/*
 * This script filters the articles table, leaving only the articles
 * in the specified subuniverse.
 *
 * Output format:
 * page_id:int, title:chararray, namespace:int, rev_date:int, rev_time:int, 
 * rev_epoch_time:long, rev_dow:int, article_text:chararray
 */

%default ARTICLES         '/data/results/wikipedia/full/articles' -- all articles in the wikipedia corpus
%default SUB_NODES        '/data/results/wikipedia/mini/nodes'    -- all nodes in the subuniverse
%default SUB_ARTICLES_OUT '/data/results/wikipedia/mini/articles' -- where output will be stored

articles = LOAD '$ARTICLES' AS (page_id:int, title:chararray, namespace:int, 
  rev_date:int, rev_time:int, rev_epoch_time:long, rev_dow:int, article_text:chararray);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);
sub_articles_unfiltered = JOIN articles BY id, sub_nodes BY node_id;
sub_articles = FOREACH sub_articles_unfiltered GENERATE
  articles::page_id AS page_id, articles::title AS title, articles::namespace AS namespace,
  articles::rev_date AS rev_date, articles::rev_time AS rev_time,
  articles::rev_epoch_time AS rev_epoch_time, articles::rev_dow AS rev_dow,
  articles::article_text AS article_text;
STORE sub_articles INTO '$SUB_ARTICLES_OUT';
