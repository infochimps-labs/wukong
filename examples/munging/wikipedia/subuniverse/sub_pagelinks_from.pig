/*
 * This script filters the pagelinks table, leaving only the pagelinks
 * that start within supplied subuniverse.
 * 
 * Output format (same as augmented_pagelinks):
 * from_id:int, into_id:int, from_namespace:int, from_title:chararray,  into_namespace:int, into_title:chararray
 */

%default PAGELINKS         '/data/results/wikipedia/full/pagelinks' -- all edges in the pagelink graph (must be *directed*)
%default SUB_NODES         '/data/results/wikipedia/mini/nodes'     -- all nodes in the subuniverse
%default SUB_PAGELINKS_OUT '/data/results/wikipedia/mini/pagelinks' -- where output will be stored

all_pagelinks = LOAD '$PAGELINKS' AS (from_id:int, into_id:int, 
  from_namespace:int, from_title:chararray,  into_namespace:int, into_title:chararray);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);

sub_pagelinks_from = JOIN all_pagelinks BY from_id, sub_nodes BY node_id;
sub_pagelinks = FOREACH sub_pagelinks_from GENERATE
  all_pagelinks::from_id, all_pagelinks::into_id, 
  all_pagelinks::from_namespace, all_pagelinks::from_title,  
  all_pagelinks::into_namespace, all_pagelinks::into_title;
STORE sub_pagelinks INTO '$SUB_PAGELINKS_OUT';
