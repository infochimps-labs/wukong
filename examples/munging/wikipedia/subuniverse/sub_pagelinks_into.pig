/*
 * This script filters the pagelinks table, leaving only the pagelinks
 * that terminate within supplied subuniverse.
 * 
 * Output format (same as augment_pagelinks):
 * node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int
 */

%default PAGELINKS         '/data/results/wikipedia/full/pagelinks' -- all edges in the pagelink graph (must be *directed*)
%default SUB_NODES         '/data/results/wikipedia/mini/nodes'     -- all nodes in the subuniverse
%default SUB_PAGELINKS_OUT '/data/results/wikipedia/mini/pagelinks' -- where output will be stored

all_pagelinks = LOAD '$PAGELINKS' AS (from_id:int, into_id:int, 
  from_namespace:int, from_title:chararray,  into_namespace:int, into_title:chararray);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);

sub_pagelinks_into = JOIN all_pagelinks BY into_id, sub_nodes BY node_id;
sub_pagelinks = FOREACH sub_pagelinks_into GENERATE
  all_pagelinks::from_id, all_pagelinks::into_id, 
  all_pagelinks::from_namespace, all_pagelinks::from_title,  
  all_pagelinks::into_namespace, all_pagelinks::into_title;
STORE sub_pagelinks INTO '$SUB_PAGELINKS_OUT';
