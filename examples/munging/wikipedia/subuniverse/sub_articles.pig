/*
 * This script filters the articles table, leaving only the articles
 * in the specified subuniverse.
 *
 * Output format:
 * page_id:int, title:chararray, namespace:int, rev_date:int, rev_time:int, 
 * rev_epoch_time:long, rev_dow:int, article_text:chararray
 */

%default NREDUCERS        10
%default ROOT             's3n://bigdata.chimpy.us'        
%default ARTICLES         '/data/results/wikipedia/full/articles.tsv' -- all articles in the wikipedia corpus
%default SUB_NODES        '/data/results/wikipedia/mini/nodes'    -- all nodes in the subuniverse
%default SUB_ARTICLES_OUT '/data/results/wikipedia/mini/articles' -- where output will be stored

articles     = LOAD '$ARTICLES' AS (
                page_id:int, namespace:int, title:chararray, 
                revision_id:long, revision_timestamp:long, redirect:chararray, article_text:chararray);
sub_nodes    = LOAD '$SUB_NODES' AS (node_id:int);
sub_articles_unfiltered = JOIN articles BY page_id, sub_nodes BY node_id PARALLEL $NREDUCERS;
sub_articles_filtered = FILTER sub_articles_unfiltered BY namespace == 0;
sub_articles = FOREACH sub_articles_filtered GENERATE
                page_id, namespace, title,
                revision_id, revision_timestamp, redirect, article_text;
STORE sub_articles INTO '$SUB_ARTICLES_OUT';
