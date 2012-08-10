#!/usr/bin/env ruby
# encoding:UTF-8

# A script that fetches the namespace -> id mapping for
# all wikipedia languages. The output is stored (by default)
# in a json file that represents a hash from namespace name => id

require 'open-uri'
require 'set'
require 'configliere'
require 'json'

Settings.use :commandline

NS_FILE = 'namespaces.json'
NS_BY_WIKI_FILE = 'namespaces_by_wiki.json'

Settings({
  out_dir: File.dirname(__FILE__),
  verbose: false,
  head_length: 100,
  std_out: false,
  arrange_by_wiki: false,
})

Settings.define :out_dir, flag: 'o', description: "Directory to drop the json namespace files into. #{File.dirname(__FILE__)} by default"
Settings.define :verbose, flag: 'v', description: "Get chatty", type: :boolean
Settings.define :head_length, flag: 'h', description: "The number of lines to read into the wiki xml for the namespace definitions. 100 by default", type: Integer
Settings.define :std_out, flag: 's', description: "Print the json to standard out.", type: :boolean
Settings.define :arrange_by_wiki, flag: 'w', description: "Structure the JSON so that it maps from wiki_prefix => ns_title => ns_id. The default is prefix => id", type: :boolean

Settings.resolve!

Settings[:out_dir] = File.expand_path(Settings[:out_dir])

namespaces = {}
namespaces_by_wiki = {}

wikis_page = open('http://dumps.wikimedia.org/backup-index.html')
wikis = Set.new

# grap the list of wikis
wikis_page.each_line do |line|
  next unless line =~ />[a-z]*wiki</
  wikis << line.gsub(/.*>([a-z]*)wiki<.*/,'\1')[0..-2]
end

if Settings[:verbose]
  $stderr.puts "Retrieved the names of #{wikis.size} wikis"
  $stderr.puts "Grabbing namespace data"
end

wikis.each_with_index do |prefix,index|
  namespaces_by_wiki[prefix] = {}
  $stderr.puts "Getting namespaces for #{prefix}.wikipedia.org" if Settings[:verbose] 
  raw = `curl -s 'http://dumps.wikimedia.org/#{prefix}wiki/latest/#{prefix}wiki-latest-pages-logging.xml.gz' | gzcat | head -n #{Settings[:head_length]}`
  raw.each_line do |line|
    next unless line =~ /.*<\/?namespace[^>]*>/
    match = /<\/?namespace key="(?<key>-?\d+)"[^>]*>(?<ns>[^<]*)<\/namespace>/.match(line)
    next if match.nil?
    namespaces[match[:ns]] = match[:key].to_i
    namespaces_by_wiki[prefix][match[:ns]] = match[:key].to_i
    $stderr.puts "    #{match[:ns]} -> #{match[:key]}" if Settings[:verbose] 
  end
  $stderr.puts "Finished getting namespaces for #{prefix}.wikipedia.org. #{wikis.size - index} wikis to go" if Settings[:verbose] 
end

if Settings[:arrange_by_wiki]
  json = namespaces_by_wiki.to_json
else
  json = namespaces.to_json
end

if Settings[:std_out]
  pp json
else
  filename = Settings[:out_dir] +"/#{Settings[:arrange_by_wiki] ? NS_BY_WIKI_FILE : NS_FILE}"
  File.open(filename, 'w') { |f| f.write(json)}
end
