pages = LOAD '$pages' AS (id:int, namespace:int, title:chararray, restrictions:chararray, counter:long, is_redirect:int, is_new:int, random:float, touched:int, page_latest:int, len:int);
pageviews = LOAD '$pageviews_extracted' AS (namespace:int, title:chararray, num_visitors:long, date:chararray, time:chararray, epoch_time:long, day_of_week:int);

first_join = JOIN pages BY (namespace,title) RIGHT OUTER, pageviews BY (namespace, title);
final = FOREACH first_join GENERATE
  pages::id, pageviews::namespace, pageviews::title,
  pageviews::num_visitors, pageviews::year, pageviews::month, pageviews::day_of_month, pageviews::hour_of_day, pageviews::epoch_time, pageviews::day_of_week;
STORE final INTO '$pageviews_results'
