#!/usr/bin/env ruby
# encoding:UTF-8

require 'open-uri'
require 'configliere'

NOAA_URL = 'http://www1.ncdc.noaa.gov/pub/data/noaa/'
Settings.use :commandline

Settings({
  years: [1901],
  verbose: false,
  out_dir: /data/rawd/noaa/isd/,
  un_gzip: false,
})

Settings.define :years, flag 'y', description: "Years to download"
Settings.define :verbose, flag 'v', description: "Get chatty", type: :boolean
Settings.define :un_gzip, flag 'g', description: "Unzip the files as they are uploaded", type: :boolean
Settings.define :out_dir, flag 'o', description: "The directory in the hdfs to put the files"

Settings.resolve!

def get_files_for_year(year)
  year_page = open("#{NOAA_URL}/#{year}")
  years = []
  year_page.each_line do |line|
    next unless line =~ /<a href="[^.]*\.gz">/
    match = /<a href="([^.]*\.gz)">/.match(line)
    years << match[1] if not match.nil?
  end
  return years
end

years.each do |year|
  puts "Uploading files for year #{year}..." if Settings[:verbose]
  get_files_for_year(year).each do |file|
    puts "  Uploading #{file}..." if Settings[:verbose]
    path = "#{NOAA_URL}/#{year}/#{file}"
    if Settings[:un_gzip]
      `curl '#{path}' | zcat | hdp-put #{Settings[:out_dir]}/#{year}/#{file}`
    else
      `curl #{file} | hdp-put #{Settings[:out_dir]}/#{year}/#{file}`
    end
  end
end
