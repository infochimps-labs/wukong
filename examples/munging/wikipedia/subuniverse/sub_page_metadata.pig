/*
 * This script filters the page metadata table, leaving only the pages 
 * in the specified subuniverse.
 *
 * Output format (same as page_metadata):
 * id:int, namespace:int, title:chararray, restrictions:chararray, counter:long, 
 * is_redirect:int, is_new:int, random:float, touched:int, page_latest:int, len:int
 */

%default PAGE_METADATA         '/data/results/wikipedia/full/page_metadata' -- metadata for all pages in the wikipedia corpus
%default SUB_NODES             '/data/results/wikipedia/mini/nodes'         -- all nodes in the subuniverse
%default SUB_PAGE_METADATA_OUT '/data/results/wikipedia/mini/page_metadata' -- where output will be stored

page_metadata = LOAD '$PAGE_METADATA' AS (id:int, namespace:int, title:chararray, 
  restrictions:chararray, counter:long, is_redirect:int, is_new:int, random:float, 
                                          touched:int, page_latest:int, len:int);
sub_nodes = LOAD '$SUB_NODES' AS (node_id:int);
sub_page_metadata_unfiltered = JOIN page_metadata BY id, sub_nodes BY node_id;
sub_page_metadata = FOREACH sub_page_metadata_unfiltered GENERATE
  page_metadata::id, page_metadata::namespace, page_metadata::title, 
  page_metadata::restrictions, page_metadata::counter, page_metadata::is_redirect, 
  page_metadata::is_new, page_metadata::random, page_metadata::touched, 
  page_metadata::page_latest, page_metadata::len;
STORE sub_page_metadata INTO '$SUB_PAGE_METADATA_OUT';
