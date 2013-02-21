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

### @export fields, parse, requested_at
class Logline
  ### @/export

  ### @export fields
  include Gorillib::Model

  field :ip_address,    String
  field :requested_at,  Time
  field :http_method,   String,  doc: "GET, POST, etc"
  field :uri_str,       String,  doc: "Combined path and query string of request"
  field :protocol,      String,  doc: "eg 'HTTP/1.1'"
  #
  field :response_code, Integer, doc: "HTTP status code (j.mp/httpcodes)"
  field :bytesize,      Integer, doc: "Bytes in response body", blankish: ['', nil, '-']
  field :referer,       String,  doc: "URL of linked-from page. Note speling."
  field :user_agent,    String,  doc: "Version info of application making the request"

  def visitor_id ; ip_address ; end
  ### @/export

  ### @export parse
  # Extract structured fields using the `raw_regexp` regular expression
  def self.parse(line)
    mm = raw_regexp.match(line.chomp) or return BadRecord.new('no match', line)
    new(mm.captures_hash)
  end
  ### @export

  ### @export requested_at
  # Map of abbreviated months to date number.
  MONTHS = { 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12 }

  def receive_requested_at(val)
    # Time.parse doesn't like the quirky apache date format, so handle those directly
    mm = %r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s([\+\-]\d\d)(\d\d)}.match(val) rescue nil
    if mm
      day, mo, yr, hour, min, sec, tz1, tz2 = mm.captures
      val = Time.new(
        yr.to_i,   MONTHS[mo], day.to_i,
        hour.to_i, min.to_i,   sec.to_i, "#{tz1}:#{tz2}")
    end
    super(val)
  end
  ### @/export

  def date_hr
    [visit_time.year, visit_time.month, visit_time.day, visit_time.hour].join
  end

  ### @export parse
  class_attribute :raw_regexp

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq?onepage=true HTTP/1.1" 200 569 "http://infochimps.org/search?query=your_mom" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  self.raw_regexp = %r{\A
               (?<ip_address>   [\w\.]+)           # ip_address     83.240.154.3
             \ (?<identd>       \S+)               # identd         -  (rarely used)
             \ (?<authuser>     \S+)               # authuser       -  (rarely used)
                                                   #
           \ \[(?<requested_at>                    #
                                \d+/\w+/\d+        # date part      [07/Jun/2008
                               :\d+:\d+:\d+        # time part      :20:37:11
                              \ [\+\-]\S*)\]       # timezone       +0000]
                                                   #
        \ \"(?:(?<http_method>  [A-Z]+)            # http_method    "GET
             \ (?<uri_str>      \S+)               # uri_str        faq?onepage=true
             \ (?<protocol>     HTTP/[\d\.]+)|-)\" # protocol       HTTP/1.1"
                                                   #
             \ (?<response_code>\d+)               # response_code  200
             \ (?<bytesize>     \d+|-)             # bytesize       569
           \ \"(?<referer>      [^\"]*)\"          # referer        "http://infochimps.org/search?query=CAC"
           \ \"(?<user_agent>   [^\"]*)\"          # user_agent     "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x
  ### @/export

  # Matches a file extension
  FILE_EXT_RE = %r{\.[^/]+\z}

  def page_type
    file_ext = uri_str[FILE_EXT_RE]
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

### @export fields, parse, requested_at
end
### @/export
