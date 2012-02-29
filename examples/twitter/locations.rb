#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path("../../lib", File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'wukong/script'

require 'models'

Settings.use :commandline
Settings.resolve!

Wukong.flow(:mapper) do |input|
  source(:stdin) |
    from_tsv     |
    map{|tuple| TwitterUser.consume_tuple(tuple) } |
    reject{|u| u.protected? }                  |
    map{   |u| [ u.user_id, u.screen_name, u.utc_offset, u.location, u.time_zone ] } |
    reject{|u| u.all?(&:blank?) }             |
    to_tsv | stdout

end

Wukong.flow(:mapper_2) do |input|
  source(:stdin) | from_tsv |
    map{|u| u[1] } |
    select(/\b(Alabama|AL|Alaska|AK|Arizona|AZ|Arkansas|AR|California|CA|cali|Colorado|CO|colo|Connecticut|CT|conn|Delaware|DE|del|Florida|FL|fla|Georgia|GA|Hawaii|HI|Idaho|ID|Illinois|IL|ill|Indiana|IN|Iowa|IA|Kansas|KS|Kentucky|KY|Louisiana|LA|Maine|ME|Maryland|MD|Massachusetts|MA|mass|Michigan|MI|mich|Minnesota|MN|minn|Mississippi|MS|miss|Missouri|MO|Montana|MT|Nebraska|NE|neb|Nevada|NV|nev|New\s*Hampshire|NH|New\s*Jersey|NJ|jersey|New\s*Mexico|NM|New\s*York|NY|North\s*Carolina|NC|North\s*Dakota|ND|n\s*dak|Ohio|OH|Oklahoma|OK|okl|Oregon|OR|Pennsylvania|PA|Rhode\s*Island|RI|r\s*isl|South\s*Carolina|SC|South\s*Dakota|SD|s\s*dak|Tennessee|TN|tenn|Texas|TX|tex|Utah|UT|Vermont|VT|Virginia|VA|Washington|WA|wash|West\s*Virginia|WV|w\s*va|Wisconsin|WI|wisc|Wyoming|WY|wyo)\b/) |
    stdout
end

Wukong::Script.new(Settings).run
