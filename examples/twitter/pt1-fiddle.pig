
locations = LOAD '/user/flip/twitter/locations' AS
        ( user_id:long, screen_name:chararray, utc_offset:long, time_zone:chararray, location:chararray );


paris = FILTER locations BY (location matches '.*paris.*');

STORE paris INTO '/user/flip/twitter/paris';
