
locations = LOAD '/user/flip/twitter/locations' AS
        ( user_id:long, screen_name:chararray, utc_offset:long, time_zone:chararray, location:chararray );

locations_matched = FOREACH locations GENERATE
        user_id,
        screen_name,
        utc_offset,
        time_zone,
        location
        , REGEX_EXTRACT(location, '(.*?\\s|^)([0-9][0-9][0-9][0-9][0-9])(\\s.*|$)', 2) AS zip
        , REGEX_EXTRACT(location, '.*(&uuml;t|iphone):\\s*(-?\\d+\\.\\d+),(-?\\d+\\.\\d+)\\b.*', 2) AS lng
        , REGEX_EXTRACT(location, '.*(&uuml;t|iphone):\\s*(-?\\d+\\.\\d+),(-?\\d+\\.\\d+)\\b.*', 3) AS lat
        , REGEX_EXTRACT(location, '(.*\\b(alabama|al|alaska|ak|arizona|az|arkansas|ar|california|ca|cali|colorado|co|colo|connecticut|ct|conn|delaware|de|del|florida|fl|fla|georgia|ga|hawaii|hi|idaho|id|illinois|il|ill|indiana|in|iowa|ia|kansas|ks|kentucky|ky|louisiana|la|maine|me|maryland|md|massachusetts|ma|mass|michigan|mi|mich|minnesota|mn|minn|mississippi|ms|miss|missouri|mo|montana|mt|nebraska|ne|neb|nevada|nv|nev|new\\s*hampshire|nh|new\\s*jersey|nj|jersey|new\\s*mexico|nm|new\\s*york|ny|north\\s*carolina|nc|north\\s*dakota|nd|n\\s*dak|ohio|oh|oklahoma|ok|okl|oregon|or|pennsylvania|pa|rhode\\s*island|ri|r\\s*isl|south\\s*carolina|sc|south\\s*dakota|sd|s\\s*dak|tennessee|tn|tenn|texas|tx|tex|utah|ut|vermont|vt|virginia|va|washington|wa|wash|west\\s*virginia|wv|w\\s*va|wisconsin|wi|wisc|wyoming|wy|wyo)\\b.*)', 1) AS us_place
        ;


SPLIT locations_matched INTO
        zips      IF (zip      IS NOT NULL),
        us_places IF (us_place IS NOT NULL),
        latlng    IF (lat      IS NOT NULL)
;

rmf /user/flip/twitter/zips /user/flip/twitter/us_places /user/flip/twitter/latlngs
rmf /user/flip/twitter/locations_matched

STORE zips      INTO '/user/flip/twitter/zips';
STORE us_places INTO '/user/flip/twitter/us_places';
STORE latlng    INTO '/user/flip/twitter/latlngs';
        
STORE locations_matched INTO '/user/flip/twitter/locations_matched';
