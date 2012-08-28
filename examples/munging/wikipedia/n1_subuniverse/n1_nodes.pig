all_edges = LOAD '$all_edges' AS (node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int);
spokes = FILTER all_edges BY (node_a == $hub) OR (node_b == $hub);
neighbors = FOREACH spokes GENERATE ((node_a == $hub) ? node_b : node_a) AS node;
distinct_neighbors = DISTINCT neighbors;
STORE distinct_neighbors INTO '$n1_nodes_out';
