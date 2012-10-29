/*
 * This script filters the pagelinks table, leaving only the pagelinks
 * that start and end within supplied subuniverse.
 * 
 * Output format (same as undirected_pagelinks):
 * node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int
 */

%default UNDIRECTED_PAGELINKS  '/data/results/wikipedia/full/undirected_pagelinks' -- all edges in the pagelink graph
%default SUB_NODES             '/data/results/wikipedia/mini/nodes'                -- all nodes in the subuniverse
%default SUB_PAGELINKS_OUT     '/data/results/wikipedia/mini/pagelinks'            -- where output will be stored

all_pagelinks = LOAD '$UNDIRECTED_PAGELINKS' AS (node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);

sub_pagelinks_in = JOIN all_pagelinks BY node_a, sub_nodes BY node_id;
sub_pagelinks_unfiltered = JOIN sub_pagelinks_in BY node_b, sub_nodes BY node_id;
sub_pagelinks = FOREACH sub_pagelinks_unfiltered GENERATE
  sub_pagelinks_in::all_pagelinks::node_a AS node_a, 
  sub_pagelinks_in::all_pagelinks::node_b AS node_b,
  sub_pagelinks_in::all_pagelinks::a_into_b AS a_into_b, 
  sub_pagelinks_in::all_pagelinks::b_into_a AS b_into_a,
  sub_pagelinks_in::all_pagelinks::is_symmetric AS is_symmetric;
STORE sub_pagelinks INTO '$SUB_PAGELINKS_OUT';
