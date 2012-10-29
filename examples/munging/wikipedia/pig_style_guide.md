# Pig Style Guide

- Everything except names should be in all caps. E.g.

		first_join = JOIN pages BY (namespace,title) 
			RIGHT OUTER, pageviews BY (namespace, title);

- Group and align columns in the script in ways that make sense. Don't be afraid of newlines. E.g.

		second_pass   = FOREACH second_pass_j GENERATE 
 		  first_pass::from_id, pages::id,
		  first_pass::from_namespace, first_pass::from_title, 
		  first_pass::into_namespace, first_pass::into_title;
		  
- Columns that form an important sub-set of the table's data should be easily accessible as a unit. 

	E.g. The edge list above has the from and into ids in the first and second columns, making it easy to just get an edge list of ids without the additional metadata.

- When at all possible, you should include sample LOAD statements in the comments for your script. This makes it easy to use the output of your script

- Parameterize as much as possible. All paths should be parameterized. 

- Parameters should be in all caps, e.g. $NODE.

- Parameters should have defaults if at all possible. When you define the default, also include a comment describing the parameter.
