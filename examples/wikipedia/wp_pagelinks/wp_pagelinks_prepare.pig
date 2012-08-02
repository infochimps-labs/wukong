/*
 A script to generate Wikipedia page graph edge list
 Accepts as input 2 tsvs: list of pages and list of links
 Link table should initially be formatted as from_page_id, into_namespace, into_title
 Link table is transformed to from_id, from_namespace, from_title, into_id, into_namespace, into_title
 Assumes that the combination of namespace and title uniquely identifies a page
*/
pages = LOAD '/data/rawd/wikipedia/wikipedia_pages/parsed' AS (id:int, namespace:int, title:chararray, restrictions:chararray, counter:long, is_redirect:int, is_new:int, random:float, touched:int, page_latest:int, len:int);
links = LOAD '/data/rawd/wikipedia/wikipedia_pagelinks/parsed' AS (from_id:int, into_namespace:int, into_title:chararray);

first_join = join pages by id right outer, links by from_id;
fixed_up_from = FOREACH first_join GENERATE 
  links::from_id AS from_id, pages::namespace AS from_namespace, pages::title AS from_title,
  links::into_namespace AS into_namespace, links::into_title AS into_title;
second_join = join pages by (namespace, title) right outer, fixed_up_from by (into_namespace, into_title);
final = foreach second_join generate 
  fixed_up_from::from_id, fixed_up_from::from_namespace, fixed_up_from::from_title, 
  pages::id,              fixed_up_from::into_namespace, fixed_up_from::into_title;
store final into '/data/rawd/wikipedia/wikipedia_pagelinks/edge_list';
