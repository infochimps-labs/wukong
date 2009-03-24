
-- ===========================================================================
--
-- Load Graph
-- 

MultiEdge               = LOAD    'twnew/all/multi_edge' AS (
  rsrc: chararray, src: int, dest: int,
  fo:     int, fr:    int,
  re_out: int, re_in: int,
  at_out: int, at_in: int,
  rt_out: int, rt_in: int,
  fv_out: int, fv_in: int) ;

SymmEdges_0   = FOREACH MultiEdge GENERATE src, dest, fo, fr ;
SymmEdges_1   = FILTER  SymmEdges_0 BY (fo >= 1.0) AND (fr >= 1.0) ;
SymmEdges     = FOREACH SymmEdges_1 GENERATE src, dest ;
-- rm twnew/graphs/symm_edges; STORE SymmEdges INTO 'twnew/graphs/symm_edges' ;
SymmEdges = LOAD 'twnew/graphs/symm_edges' AS (src:int , dest:int);

AnyoutEdges_0 = FOREACH MultiEdge GENERATE src, dest, fo, re_out, fv_out ;
AnyoutEdges_1 = FILTER AnyoutEdges_0 BY (fo >= 1.0) OR (re_out >= 1.0) OR (fv_out >= 1.0) ;
AnyoutEdges   = FOREACH AnyoutEdges_1 GENERATE src, dest ;
-- rm twnew/graphs/anyout_edges; STORE AnyoutEdges INTO 'twnew/graphs/anyout_edges' ;
AnyoutEdges = LOAD 'twnew/graphs/anyout_edges' AS (src:int , dest:int);


-- InitPagerankSymm_0 = GROUP SymmEdges BY src ;
-- InitPagerankSymm_1 = FOREACH InitPagerankSymm_0 GENERATE
--   group                 AS src,
--   1.0F                  AS pagerank:float,
--   SymmEdges.(dest)  AS dests
--   ;
-- rm                             twnew/pagerank-symm/pagerank_000_graph ;
-- STORE InitPagerankSymm_1 INTO 'twnew/pagerank-symm/pagerank_000_graph';


InitPagerankAnyout_0 = GROUP   AnyoutEdges BY src ;
InitPagerankAnyout_1 = FOREACH InitPagerankAnyout_0 GENERATE
  group                 AS src,
  1.0F                  AS pagerank:float,
  AnyoutEdges.(dest)  AS dests
  ;
rm                               twnew/pagerank-anyout/pagerank_000_graph ;
STORE InitPagerankAnyout_1 INTO 'twnew/pagerank-anyout/pagerank_000_graph';
