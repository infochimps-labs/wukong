#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

class Logline < Struct.new(
  :ip, :date, :time, :http_method, :protocol, :path, :response_code, :duration, :referer, :ua, :tz)

  def page_type
    case
    when path =~ /\.(css|js)$/                  then :asset
    when path =~ /\.(png|gif|ico)$/             then :image
    when path =~ /\.(pl|s?html?|asp|jsp|cgi)$/  then :page
    else                                             :other
    end
  end

  def is_page?
    page_type == :page
  end

  def day_hr
    visit.date + visit.time[0..1]
  end
end


#
# Group all visitors, and then troll through all the pages they've visited
# breaking each into distinct visits (where more than an [hour|day|whatever]
# separate subsequent pageviews
#

#
# Mapper parses log files and created a visitor_id from the visitor's user_id,
# cookie or ip. It emits
#
#    <visitor_id>  <datetime>   <url_path>
#
# where the partition key is visitor_id, and we sort by visitor_id and datetime.
#
class VisitorDatePath < Wukong::Streamer::StructStreamer
  def process visit, *args
    yield [visit.ip, visit.day_hr, visit.path]
  end
end

#
# Reducer:
#
# The reducer is given all page requests for the given visitor id, sorted by
# timestamp.
#
# It group by visits (pageviews separated by more than DISTINCT_VISIT_TIMEGAP)
# and emits
#
#     trail        <visitor_id> <n_pages_in_visit> <duration> <timestamp> < page1,page2,... >
#
# where the last is a comma-separated string of URL encoded paths (any internal comma is converted to %2C).
#
# You can instead emit
#
#     page_trails  <page1>      <n_pages_in_visit> <duration> <timestamp> < page1,page2,... >
#     page_trails  <page2>      <n_pages_in_visit> <duration> <timestamp> < page1,page2,... >
#     ....
#     page_trails  <pagen>      <n_pages_in_visit> <duration> <timestamp> < page1,page2,... >
#
# to discover all trails passing through a given page.
class VisitorDatePath < Wukong::Streamer::Reducer
  def get_key ip, day_hr, path, *args
    [ip, day_hr]
  end
  def process_group visit, *args
    yield [visit.ip, visit.day_hr, visit.path]
  end
end
