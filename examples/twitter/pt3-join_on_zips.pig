zips  = LOAD '/user/flip/twitter/zips/part-m-00000' AS
        ( user_id:long, screen_name:chararray, utc_offset:long, time_zone:chararray, location:chararray,
          postal_code:chararray, lng:float, lat:float, us_place:chararray);

-- http://download.geonames.org/export/zip/
-- 
-- country code      : iso country code, 2 characters
-- postal code       : varchar(20)
-- place name        : varchar(180)
-- admin name1       : 1. order subdivision (state) varchar(100)
-- admin code1       : 1. order subdivision (state) varchar(20)
-- admin name2       : 2. order subdivision (county/province) varchar(100)
-- admin code2       : 2. order subdivision (county/province) varchar(20)
-- admin name3       : 3. order subdivision (community) varchar(100)
-- admin code3       : 3. order subdivision (community) varchar(20)
-- latitude          : estimated latitude (wgs84)
-- longitude         : estimated longitude (wgs84)
-- accuracy          : accuracy of lat/lng from 1=estimated to 6=centroid        

us_postal_codes = LOAD 'twitter/US.txt' AS (cc:chararray, postal_code:chararray,
  place_name:chararray, admin_name1:chararray, admin_code1:chararray,
  admin_name2:chararray, admin_code2:chararray, admin_name3:chararray,
  admin_code3:chararray, lat:float, lng:float, accuracy:int);

us_postal_codes_b = FOREACH us_postal_codes GENERATE postal_code, lat, lng;

zips_matched_a = JOIN zips BY postal_code, us_postal_codes_b BY postal_code;

zips_matched_b = FOREACH zips_matched_a GENERATE
        user_id, screen_name, utc_offset, time_zone, location,
        us_postal_codes_b::postal_code AS postal_code,
        us_postal_codes_b::lng         AS lng,
        us_postal_codes_b::lat         AS lat,
        us_place
        ;

rmf /user/flip/twitter/zips_matched

STORE zips_matched_b  INTO '/user/flip/twitter/zips_matched';
