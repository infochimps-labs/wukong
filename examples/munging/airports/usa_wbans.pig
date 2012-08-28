// Outputs a list of WBAN ids that are assigned to airports in the USA

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

mshr_grouped = GROUP mshr BY (icao_id, wban_id, faa_id, fips_country_code);
mshr_flattened = FOREACH mshr_grouped GENERATE FLATTEN(group) AS (wban_id, icao_id, faa_id, fips_country_code);
mshr_filtered = FILTER mshr_flattened BY (icao_id is not null and wban_id is not null and fips_country_code == 'US');

mshr_final = FOREACH mshr_filtered GENERATE wban_id;
STORE mshr_final INTO '/Users/dlaw/Desktop/stations/usa_wbans';
