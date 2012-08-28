all_edges = LOAD '$undirected_pagelinks' AS (node_a:int, node_b:int, a_into_b:int, b_into_a:int, is_symmetric:int);
distinct_neighbors = LOAD '$n1_nodes' AS (node:int);

n1_edges_in = JOIN all_edges BY node_a, distinct_neighbors BY node;
n1_edges_unfiltered = JOIN n1_edges_in BY node_b, distinct_neighbors BY node;
n1_edges = FOREACH n1_edges_unfiltered GENERATE
  n1_edges_in::all_edges::node_a AS node_a, 
  n1_edges_in::all_edges::node_b AS node_b,
  n1_edges_in::all_edges::a_into_b AS a_into_b, 
  n1_edges_in::all_edges::b_into_a AS b_into_a,
  n1_edges_in::all_edges::is_symmetric AS is_symmetric;
STORE n1_edges INTO '$n1_edges';
