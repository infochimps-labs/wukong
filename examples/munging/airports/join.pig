/* This was a misguided attempt at generating a list of WBAN IDs assigned to airports by filtering the mshr_enhanced
 * and joining it with isd_stations. This is misguided because mshr_enhanced contains much more data than isd_stations,
 * and also contains multiple entries for each weather station, making it non-obvious how best to join the data.
 * A simpler and better approach, taken in usa_wbans.pig and wbans.pig, is to filter and unique mshr_enhanced.
 */

mshr = LOAD '/Users/dlaw/Desktop/stations/mshr_enhanced.tsv' AS 
 (source_id:chararray, source:chararray, begin_date:chararray, end_date:chararray, station_status:chararray, 
  ncdcstn_id:chararray, icao_id:chararray, wban_id:chararray, faa_id:chararray, nwsli_id:chararray, wmo_id:chararray, 
  coop_id:chararray, transmittal_id:chararray, ghcnd_id:chararray, name_principal:chararray, name_principal_short:chararray, 
  name_coop:chararray, name_coop_short:chararray, name_publication:chararray, name_alias:chararray, nws_clim_div:chararray, 
  nws_clim_div_name:chararray, state_prov:chararray, county:chararray, nws_st_code:chararray, fips_country_code:chararray, 
  fips_country_name:chararray, nws_region:chararray, nws_wfo:chararray, elev_ground:chararray, elev_ground_unit:chararray, 
  elev_barom:chararray, elev_barom_unit:chararray, elev_air:chararray, elev_air_unit:chararray, elev_zerodat:chararray, 
  elev_zerodat_unit:chararray, elev_unk:chararray, elev_unk_unit:chararray, lat_dec:chararray, lon_dec:chararray, 
  lat_lon_precision:chararray, relocation:chararray, utc_offset:chararray, obs_env:chararray, platform:chararray);

mshr_grouped = GROUP mshr BY (icao_id, wban_id, faa_id, begin_date, end_date);
mshr_final = FOREACH mshr_grouped GENERATE FLATTEN(group) AS (wban_id, icao_id, faa_id, begin_date, end_date);

stations = LOAD '/Users/dlaw/Desktop/stations/stations.tsv' AS
 (usaf_id:chararray, wban_id:chararray, station_name:chararray, wmo_country_id:chararray, fips_country_id:chararray, 
 state:chararray, icao_call_sign:chararray, latitude:chararray, longitude:chararray, elevation:chararray, begin:chararray, end:chararray);

first_pass_j = JOIN mshr_final BY (wban_id) RIGHT OUTER, stations BY (wban_id);
first_pass_f = FILTER first_pass_j BY (mshr_final::icao_id is not null);
first_pass = FOREACH first_pass_f GENERATE
  stations::wban_id, mshr_final::icao_id, stations::icao_call_sign, stations::usaf_id,  mshr_final::faa_id, 
  stations::station_name, stations::wmo_country_id, stations::fips_country_id, stations::state, stations::latitude, stations::longitude, stations::elevation, stations::begin, stations::end;

STORE first_pass INTO '/Users/dlaw/Desktop/stations/airport_stations';
