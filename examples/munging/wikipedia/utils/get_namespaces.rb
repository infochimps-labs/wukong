#!/usr/bin/env ruby
# encoding:UTF-8

# A script that fetches the namespace -> id mapping for
# all wikipedia languages. The output is stored (by default)
# in a json file that represents a hash from namespace name => id

require 'ruby-progressbar'
require 'open-uri'
require 'set'
require 'configliere'
require 'json'

Settings.use :commandline

NS_FILE = 'namespaces'

Settings.define :out_dir, flag: 'o', description: "Directory to drop the namespace file into.", default: File.expand_path(File.dirname(__FILE__))
Settings.define :verbose, flag: 'v', description: "Get chatty", type: :boolean, default: false
Settings.define :silent, description: "Say nothing", type: :boolean, default: false
Settings.define :head_length, flag: 'h', description: "The number of lines to read into the wiki xml for the namespace definitions.", type: Integer, default: 100
Settings.define :std_out, flag: 's', description: "Print output to standard out.", type: :boolean, default: false
Settings.define :to_tsv, flag: 't', description: 'Format the output as a TSV instead of JSON', type: :boolean, default:false

Settings.resolve!

Settings.out_dir = File.expand_path(Settings.out_dir)

namespaces = {}
namespaces_by_wiki = {}

wikis_page = open('http://dumps.wikimedia.org/backup-index.html')
wikis = Set.new

# grap the list of wikis
wikis_page.each_line do |line|
  next unless line =~ />[a-z]*wiki</
  wikis << line.gsub(/.*>([a-z]*)wiki<.*/,'\1')[0..-2]
end

if Settings.verbose
  $stderr.puts "Retrieved the names of #{wikis.size} wikis"
  $stderr.puts "Grabbing namespace data"
elsif (not Settings.silent)
  progressbar = ProgressBar.create(:title => "Retrieving Namespaces...", :total => wikis.size, :format => '%t |%B| %c/%C %e  ')
end

wikis.each_with_index do |prefix,index|
  progressbar.increment unless (Settings.silent or Settings.verbose)
  namespaces_by_wiki[prefix] = {}
  $stderr.puts "Getting namespaces for #{prefix}.wikipedia.org" if Settings.verbose
  raw = `curl -s 'http://dumps.wikimedia.org/#{prefix}wiki/latest/#{prefix}wiki-latest-pages-logging.xml.gz' | gzcat | head -n #{Settings.head_length}`
  #TODO: Make this actually work
  if $?.exitstatus != 0
    out = "Could not access page dump for #{prefix}wiki." +
          " This dump is probably being updated now." + 
          " Namespaces for this wiki will not be included in the final output"
    $stderr.puts out
    next
  end
  raw.each_line do |line|
    next unless line =~ /.*<\/?namespace[^>]*>/
    match = /<\/?namespace key="(?<key>-?\d+)"[^>]*>(?<ns>[^<]*)<\/namespace>/.match(line)
    next if match.nil?
    namespaces[match[:ns]] = match[:key].to_i
    namespaces_by_wiki[prefix][match[:ns]] = match[:key].to_i
    $stderr.puts "    #{match[:ns]} -> #{match[:key]}" if Settings.verbose 
  end
  $stderr.puts "Finished getting namespaces for #{prefix}.wikipedia.org. #{wikis.size - index} wikis to go" if Settings.verbose
end

if Settings.to_tsv
  output = ""
  namespaces.each_pair do |k,v|
    output += "#{k}\t#{v}\n"
  end
else
  output = namespaces.to_json
end

if Settings.std_out
  pp output
else
  filename = "#{Settings.out_dir}/#{NS_FILE}.#{Settings.to_tsv ? "tsv" : "json"}"
  File.open(filename, 'w') { |f| f.write(output)}
end
