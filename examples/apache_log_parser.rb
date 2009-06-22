#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../lib'
require 'wukong'

module ApacheLogParser
  class Mapper < Wukong::Streamer::LineStreamer


    def parse_request req
      m = %r{\A(\w+) (.*) (\w+/[\w\.]+)\z}.match(req)
      if m
        [''] + m.captures
      else
        [req, '', '', '']
      end
    end


    # regular expression to match on apache-style log lines
    #             IP addr              -         -        [07/Jun/2008:20:37:11 +0000]               400   "GET /faq" + gaJsHost + "google-analytics.com/ga.js HTTP/1.1" 173 "-" "-" "-"
    LOG_RE = %r{\A(\d+\.\d+\.\d+\.\d+) ([^\s]+) ([^\s]+) \[(\d\d/\w+/\d+):(\d\d:\d\d:\d\d)([^\]]*)\] (\d+) "([^\"]*(?:\" \+ gaJsHost \+ \"[^\"]*)?)" (\d+) "([^\"]*)" "([^\"]*)" "([^\"]*)"\z}

    def process line
      line.chomp
      m = LOG_RE.match(line)
      if m
        ip, j1, j2, datepart, timepart, tzpart, resp, req, j3, ref, ua, j4 = m.captures
        req_date = DateTime.parse("#{datepart} #{timepart} #{tzpart}").to_flat
        req, method, path, protocol = parse_request(req)
        yield [:logline, method, path, protocol, ip, j1, j2, req_date, resp, req, j3, ref, ua, j4]
      else
        yield [:unparseable, line]
      end
    end
  end

  class Reducer < Wukong::Streamer::LineStreamer
  end

  # Execute the script
  class Script < Wukong::Script
    def reduce_command
      "/usr/bin/uniq"
    end
    def default_options
      super.merge :sort_fields => 8 # , :reduce_tasks => 0
    end
  end

  Script.new(Mapper,nil).run
end

# 55.55.155.55 - - [04/Feb/2008:11:37:52 +0000] 301 "GET /robots.txt HTTP/1.1" 185 "-" "WebAlta Crawler/2.0 (http://www.webalta.net/ru/about_webmaster.html) (Windows; U; Windows NT 5.1; ru-RU)" "-"
