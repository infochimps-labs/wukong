/*
 * Augments raw pageview data with page ID.
 * Pageview stats are *theoretically* uniquely keyed by namespace 
 * and title, so that is what is used to join pageviews with page_metadata.
 *
 * In practice, the original pageview stats only give the URL visited, and
 * reliably extracting namespace and title from the URL is difficult. Additionally, 
 * page names change, redirects happen, and many other small things can go 
 * wrong with the join. All pageview data is kept in the final table, but 
 * the page id will be blank in rows where the join failed.
 *
 * Output format:
 * page_id:int, namespace:int, title:chararray, num_visitors:long, 
 * date:int, time:int, epoch_time:long, day_of_week:int
 */

%default PAGE_METADATA           '/data/results/wikipedia/full/page_metadata' -- page metadata for all Wikipedia pages
%default EXTRACTED_PAGEVIEWS     '/data/scratch/wikipedia/full/pageviews'     -- raw extracted pageview stats (see extract_pageviews.rb)
%default AUGMENTED_PAGEVIEWS_OUT '/data/results/wikipedia/full/pageviews'     -- where output will be stored

page_metadata = LOAD '$PAGE_METADATA' AS 
 (id:int, namespace:int, title:chararray, 
  restrictions:chararray, counter:long, is_redirect:int, is_new:int, 
  random:float, touched:int, page_latest:int, len:int);
pageviews = LOAD '$EXTRACTED_PAGEVIEWS' AS (namespace:int, title:chararray, 
  num_visitors:long, date:int, time:int, epoch_time:long, day_of_week:int);

first_join = JOIN page_metadata BY (namespace, title) RIGHT OUTER, pageviews BY (namespace, title);
final = FOREACH first_join GENERATE
  page_metadata::id, pageviews::namespace, pageviews::title, pageviews::num_visitors,
  pageviews::date, pageviews::time, pageviews::epoch_time, pageviews::day_of_week;
STORE final INTO '$AUGMENTED_PAGEVIEWS_OUT';
