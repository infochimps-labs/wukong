/*
 * Takes a directed edge list and transforms it into an undirected edge list 
 * that stores edge direction as metadata.
 * 
 * Input table should be of the format (from_id:int, into_id:int ... )
 *
 * Output format:
 * from_id:int, into_id:int, a_into_b:int , b_into_a:int, symmetric:int
 *
 * a_into_b, b_into_a, and symmetric are really booleans.
 */

%default AUGMENTED_PAGELINKS      '/data/results/wikipedia/full/pagelinks'            -- all wikipedia pagelinks (see augment_pagelinks.pig)
%default UNDIRECTED_PAGELINKS_OUT '/data/results/wikipedia/full/undirected_pagelinks' -- undirected pagelinks

edges = LOAD '$AUGMENTED_PAGELINKS' AS (from:int, into:int);
edges_sorted = FOREACH edges GENERATE 
  ((from <= into)? from : into) AS node_a,
  ((from <= into)? into : from) AS node_b,
  ((from <= into)? 1 : 0) AS a_to_b,
  ((from <= into)? 0 : 1) AS b_to_a;
edges_grouped = GROUP edges_sorted by (node_a, node_b);
edges_final = FOREACH edges_grouped GENERATE 
  group.node_a AS node_a,
  group.node_b AS node_b,
  ((SUM(edges.$2) > 0) ? 1:0) AS a_into_b,
  ((SUM(edges.$3) > 0) ? 1:0) AS b_into_a,
  ((SUM(edges.$2) > 0 AND SUM(edges.$3) > 0) ? 1:0) as symmetric:int;
STORE edges final INTO '$UNDIRECTED_PAGELINKS_OUT';
