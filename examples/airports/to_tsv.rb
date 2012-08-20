#!/usr/bin/env ruby
load 'flat/lib/flat.rb'

# This is a script that uses the flat file parser
# to transform the mshr enhanced data file and the 
# ISD stations list from fixed-width to .tsv.
# The script must be in the same directory with 
# mshr_enhanced.txt, isd_stations.txt, and the
# flat file parsing library to work.

# mshr-enhanced format description can be found at
# ftp://ftp.ncdc.noaa.gov/pub/data/homr/docs/MSHR_Enhanced_Table.txt

# The actual mshr-enhanced table can be found at 
# http://www.ncdc.noaa.gov/homr/file/mshr_enhanced.txt.zip

# isd_stations can be found at
# http://www1.ncdc.noaa.gov/pub/data/noaa/ish-history.txt

# Format strings
MSHR_FORMAT_STRING = %{s20 s10 s8 s8 s20 s20 s20 s20 s20 s20 s20 s20 s20 s20
                       s100 s30 s100 s30 s100 s100 s10 s40 s10 s50 s2 s2 s100 
                       s30 s10 s40 s20 s40 s20 s40 s20 s40 s20 s40 s20 s20 s20 
                       s10 s62 s16 s40 s100}
ISD_FORMAT_STRING = %{s6 s5 s29 s2 s2 s2 s5 D6e3 D7e3 D6e1 _2 s8 s8}

# Parse mshr_enhanced
mshr_parser = Flat.create_parser(MSHR_FORMAT_STRING,1)
mshr_parser.file_to_tsv('mshr_enhanced.txt','mshr_enhanced.tsv')

# Parse isd_stations
isd_parser = Flat.create_parser(ISD_FORMAT_STRING,1,false)
isd_parser.file_to_tsv('isd_stations.txt','isd_stations.tsv')
