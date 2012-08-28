# Pig Style Guide

- Everything except names should be in all caps. E.g.

		first_join = JOIN pages BY (namespace,title) 
			RIGHT OUTER, pageviews BY (namespace, title);

- Group and align columns in the script in ways that make sense. Don't be afraid of newlines. E.g.

		second_pass   = FOREACH second_pass_j GENERATE 
 		  first_pass::from_id, pages::id,
		  first_pass::from_namespace, first_pass::from_title, 
		  first_pass::into_namespace, first_pass::into_title;
		  
- Columns that of data that form an important sub-set of the table's data should be easily accessible as a unit. 

	E.g. The edge list above has the from and into ids in the first and second columns, making it easy to just get an edge list of ids without the additional metadata.

