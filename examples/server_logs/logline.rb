# # Parse logs to TSV
#
# bzcat  data/star_wars_kid.log.bz2 | head -n 100200 | tail -n 100 > data/swk-100.log
# cat data/swk-100.tsv
# cat data/swk-100.log | ./apache_log_parser.rb --map | wu-lign | cutc 150
# cat data/swk-100.log | ./apache_log_parser.rb --map > data/swk-100.tsv
# ./histograms.rb --run data/star_wars_kid.log data/star_wars_kid.tsv

# # Histograms
#
# cat data/swk-100.tsv | ./histograms.rb --map | wu-lign
# cat data/swk-hist-map.tsv | ./histograms.rb --reduce
# ./histograms.rb --run data/star_wars_kid.tsv data/star_wars_kid-pages_by_hour.tsv

# # Sessionize
#
# cat data/swk-100.tsv | ./histograms.rb --map | wu-lign
# cat data/swk-hist-map.tsv | ./histograms.rb --reduce
# ./histograms.rb --run data/star_wars_kid.tsv data/star_wars_kid-pages_by_hour.tsv

class Logline
  include Gorillib::Model
  include Gorillib::Model::PositionalFields

  field :ip,            String
  field :junk1,         String
  field :junk2,         String
  #
  field :visit_time,    Time
  field :http_method,   String
  field :path,          String
  field :protocol,      String
  field :response_code, Integer
  field :size,          Integer, blankish: ['', nil, '-']
  field :referer,       String
  field :ua,            String
  field :cruft,         String

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq HTTP/1.1" 200 569 "http://infochimps.org/search?query=CAC" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  LOG_RE = Regexp.compile(%r{\A
               (\S+)           # ip             83.240.154.3
             \s(\S+)           # j1             -
             \s(\S+)           # j2             -
           \s\[(\d+/\w+/\d+    # date part      [07/Jun/2008
               :\d+:\d+:\d+    # time part      :20:37:11
             \s[\+\-]\S*)\]    # timezone       +0000]
        \s\"(?:(\S+)           # http_method    "GET
             \s(\S+)           # path           /faq
             \s(\S+)|-)\"      # protocol       HTTP/1.1"
             \s(\d+)           # response_code  200
             \s(\d+|-)         # size           569
           \s\"([^\"]*)\"      # referer        "http://infochimps.org/search?query=CAC"
           \s\"([^\"]*)\"      # ua             "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x)
  MONTHS = { 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12, }

  def receive_visit_time(val)
    if %r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s([\+\-]\d\d)(\d\d)} === val
      day, mo, yr, hour, min, sec, tz1, tz2 = [$1, $2, $3, $4, $5, $6, $7, $8]
      val = Time.new(yr.to_i, MONTHS[mo], day.to_i,
        hour.to_i, min.to_i, sec.to_i, "#{tz1}:#{tz2}")
    end
    super(val)
  end

  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.parse(line)
    m = LOG_RE.match(line.chomp) or return BadRecord.new('no match', line)
    new(* m.captures)
  end

  FILE_EXT_RE = %r{\.[^/]+\z}
  def page_type
    file_ext = path[FILE_EXT_RE]
    case file_ext
    when nil                        then 'page'
    when '.wmv'                     then 'video'
    when '.html','.shtml'           then 'page'
    when '.css', '.js'              then 'asset'
    when '.png', '.gif', '.ico'     then 'image'
    when '.wmv'                     then 'image'
    when '.pl','.asp','.jsp','.cgi' then 'page'
    else                                 'other'
    end
  end

  def day_hr
    [visit_time.year, visit_time.month, visit_time.day, visit_time.hour].join
  end
end
