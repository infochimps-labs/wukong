#!/usr/bin/env ruby -E BINARY
require 'rubygems'
require 'faraday'
require 'wukong/script'
require 'json'
$: << File.dirname(__FILE__)
require 'apache_log_parser'
require 'nook/faraday_dummy_adapter'

Settings.define :target_host,   :default => 'localhost', :description => "The host name or IP address to target"
Settings.define :target_scheme, :default => 'http',      :description => "Request scheme (http, https)"

#
# A Nook consumes its input stream and, for each input, generates an HTTP
# request against a remote host. Please use it for good and never for evil.
#
# You can use it from your command line:
#   zcat /var/www/app/current/log/*access*.log.gz | ./nook.rb --map --host=http://my_own_host.com
#
#
class NookMapper < ApacheLogParser

  # create a Logline object from each record and serialize it flat to disk
  def process line
    super(line) do |logline|
      # yield logline
      resp = fetcher.get("/your/mom")
      yield [resp.status, resp.body, resp.headers.inspect]
    end
  end

  # a mock fetcher with a uniformly distributed variable delay
  def fetcher
    @fetcher ||= Faraday::Connection.new do |f|
      f.use Faraday::Adapter::Dummy do |dummy|
        dummy.delay = Proc.new{|env| 0.1 + 0.9 * rand() }
      end
    end
  end
end

Wukong.run( NookMapper, nil, :sort_fields => 7 )
