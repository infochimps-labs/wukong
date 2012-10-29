/*
 * This script filters the pagelinks table, leaving only the pagelinks
 * that start and end within supplied subuniverse.
 * 
 * Output format (same as augment_pagelinks):
 * from_id:int, into_id:int, from_namespace:int, from_title:chararray,  into_namespace:int, into_title:chararray
 */

%default PAGELINKS         '/data/results/wikipedia/full/undirected_pagelinks' -- all edges in the pagelink graph
%default SUB_NODES         '/data/results/wikipedia/mini/nodes'                -- all nodes in the subuniverse
%default SUB_PAGELINKS_OUT '/data/results/wikipedia/mini/pagelinks'            -- where output will be stored

all_pagelinks = LOAD '$PAGELINKS' AS (from_id:int, into_id:int, 
  from_namespace:int, from_title:chararray,  into_namespace:int, into_title:chararray);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);

sub_pagelinks_in = JOIN all_pagelinks BY from_id, sub_nodes BY node_id;
sub_pagelinks_unfiltered = JOIN sub_pagelinks_in BY into_id, sub_nodes BY node_id;
sub_pagelinks = FOREACH sub_pagelinks_unfiltered GENERATE
  sub_pagelinks_in::all_pagelinks::from_id,
  sub_pagelinks_in::all_pagelinks::into_id,
  sub_pagelinks_in::all_pagelinks::from_namespace,
  sub_pagelinks_in::all_pagelinks::from_title,
  sub_pagelinks_in::all_pagelinks::into_namespace,
  sub_pagelinks_in::all_pagelinks::into_title;
STORE sub_pagelinks INTO '$SUB_PAGELINKS_OUT';
