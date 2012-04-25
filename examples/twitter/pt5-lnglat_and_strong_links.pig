
locations = LOAD '/user/flip/twitter/zips_matched' AS (
          user_id:long, screen_name:chararray, utc_offset:long, time_zone:chararray, location:chararray,
          postal_code:chararray, lng:float, lat:float, us_place:chararray);

locations_ll = FILTER locations BY ((lat IS NOT NULL AND lat != 0) AND (lng IS NOT NULL AND lng != 0));

strong_links = LOAD 'twitter/strong_links' AS (user_a_id:long, user_b_id:long);

loc_nbhds_j = JOIN strong_links by user_b_id, locations_ll BY user_id;

loc_nbhds = FOREACH loc_nbhds_j GENERATE user_a_id, user_id, screen_name, utc_offset, time_zone, location, postal_code, lng, lat, us_place;

rmf /user/flip/twitter/loc_nbhds

STORE loc_nbhds  INTO '/user/flip/twitter/loc_nbhds';
