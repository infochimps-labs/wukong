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
