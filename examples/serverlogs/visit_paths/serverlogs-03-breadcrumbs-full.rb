#!/usr/bin/env ruby
require          'configliere'
Settings.define :page_types, type: Array, default: ['page', 'video'], description: "Acceptable page types"
require_relative './common'

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
class BreadcrumbsMapper < Wukong::Streamer::ModelStreamer
  self.model_klass = Logline
  def process visit, *args
    # return unless Settings.page_types.include?(visit.page_type)
    yield [visit.ip, visit.day_hr, visit.requested_at.to_i, visit.path]
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
class BreadcrumbsReducer < Wukong::Streamer::Reducer
  def get_key ip, day_hr, itime, path, *args
    [ip]
  end
  def start!(*args)
    @path_times = []
    super
  end
  def accumulate ip, day_hr, itime, path, *args
    @path_times << "(#{itime},#{path})"
  end
  def finalize
    path_times_str = ("{" << @path_times.join(",") << "}")
    yield [key, path_times_str]
  end
end


Wukong.run( BreadcrumbsMapper, BreadcrumbsReducer, :sort_fields => 2 )
