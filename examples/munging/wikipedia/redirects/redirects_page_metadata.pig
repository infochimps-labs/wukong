/*
 * Filters the page metadata table, leaving only pages that 
 * are redirects.
 *
 * Output Format (same as page_metadata):
 * (id:int, namespace:int, title:chararray, restrictions:chararray, 
 * counter:long, is_redirect:int, is_new:int, random:float,  touched:int, 
 * page_latest:int, len:int)
 */

%default PAGE_METADATA '/data/results/wikipedia/full/page_metadata' -- page metdata for all pages in Wikipedia
%default REDIRECTS_OUT '/data/results/wikipedia/full/redirect_page_metadata' -- place to store page metdata for redirects

page_metadata = LOAD '$PAGE_METADATA' AS (id:int, namespace:int, title:chararray, 
  restrictions:chararray, counter:long, is_redirect:int, is_new:int, random:float, 
  touched:int, page_latest:int, len:int);

redirects = FILTER page_metadata BY (is_redirect == 1);
STORE redirects INTO '$REDIRECTS_OUT';
