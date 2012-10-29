/*
 * This script filters the pageviews table, leaving only the pageviews
 * in the specified subuniverse.
 *
 * Parameters:
 * pageviews - all pageviews in the wikipedia corpus
 * sub_nodes - the list of nodes in your subuniverse
 * sub_pageviews_out - the directory where output will be stored
 * 
 * Output format (same as pageviews_augment.pig):
 * id:int, namespace:int, 
 * page_id:int, title:chararray, namespace:int, rev_date:int, rev_time:int, 
 * rev_epoch_time:long, rev_dow:int, article_text:chararray
 */

%default PAGEVIEWS         '/data/results/wikipedia/full/pageviews' -- all pageview stats for the English Wikipedia
%default SUB_NODES         '/data/results/wikipedia/mini/nodes'     -- all nodes in the subuniverse
%default SUB_PAGEVIEWS_OUT '/data/results/wikipedia/mini/pageviews' -- where output will be stored

pageviews = LOAD '$PAGEVIEWS' AS (page_id:int, title:chararray, namespace:int, 
  rev_date:int, rev_time:int, rev_epoch_time:long, rev_dow:int, article_text:chararray);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);
sub_pageviews_unfiltered = JOIN pageviews BY id, sub_nodes BY node_id;
sub_pageviews = FOREACH sub_pageviews_unfiltered GENERATE
  articles::page_id AS page_id, articles::title AS title, articles::namespace AS namespace,
  articles::rev_date AS rev_date, articles::rev_time AS rev_time,
  articles::rev_epoch_time AS rev_epoch_time, articles::rev_dow AS rev_dow,
  articles::article_text AS article_text;
STORE sub_pageviews INTO '$SUB_PAGEVIEWS_OUT';
