/*
 * This script generates the list of all nodes in the 1-neighborhood of the specified node.
 * 
 * Output Format:
 * node_id:int
 */

%default UNDIRECTED_PAGELINKS  '/data/results/wikipedia/full/undirected_pagelinks' -- all edges in the pagelink graph
%default HUB1                  78882                                               -- Chimpanzee
%default HUB2                  9279                                                -- Elephant
%default N1_NODES_OUT          '/data/results/wikipedia/mini/nodes'                -- where output will be stored

undirected_pagelinks = LOAD     '$UNDIRECTED_PAGELINKS' AS (node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int);
spokes               = FILTER   undirected_pagelinks BY (node_a == $HUB1) OR (node_b == $HUB1) OR (node_a == $HUB2) OR (node_b == $HUB2);
neighbors            = FOREACH  spokes GENERATE ((node_a == $HUB) ? node_b : node_a) AS node;
distinct_neighbors   = DISTINCT neighbors PARALLEL 1;
STORE distinct_neighbors INTO '$N1_NODES_OUT';
