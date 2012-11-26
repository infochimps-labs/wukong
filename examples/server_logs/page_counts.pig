

LOAD  common_pages       FROM 'data/common_pages' AS (ip:chararray, from_path:chararray, into_path:chararray);

--
-- Build adjacency list <A pr B,C,D> from edges (<A B>, <A C>, <A D>)
-- 

adj_list_j         = GROUP common_pages BY from_path;
adj_list           = FOREACH adj_list_j GENERATE
  group                   AS from_path,
  1.0F                    AS pagerank:float,
  common_pages.(dest)     AS into_paths
  ;
STORE adj_list INTO 'data/pagerank/pr_iter_00';


--
-- Iterate pagerank <A pr_00 B,C,D> to become <A pr_01 B,C,D>
--

--   find partial share: A.rank / A.into_paths.length
--   dispatch <into_path partial_share> to each page
sent_shares  = FOREACH adj_list GENERATE
        FLATTEN(into_paths)                         AS path,
        (float)(pagerank / (float)SIZE(into_paths)) AS share:float;

--   dispatch <from_path into_paths>    to yourself, so you have the links still around
sent_edges   = FOREACH adj_list GENERATE
        from_path AS path, into_paths;

--   assemble all the received shared, and the self-sent edge list;
rcvd_shares  = COGROUP sent_edges BY path INNER, sent_shares BY path PARALLEL $PARALLEL;

--   calculate the new rank, and emit a record that looked just like the input.
next_iter    = FOREACH rcvd_shares {
        raw_rank    = (float)SUM(sent_shares.share);
        -- treat the case that a node has no in links                   
        damped_rank = ((raw_rank IS NOT NULL AND raw_rank > 1.0e-12f) ? raw_rank*0.85f + 0.15f : 0.0f);
        GENERATE
                group         AS from_path,
                damped_rank   AS rank,
                FLATTEN(sent_edges.into_paths)
       ; };

STORE next_iter INTO 'data/pagerank/pr_iter_01';


