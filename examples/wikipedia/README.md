## Encodings
SQL dumps are theoretically encoded in UTF-8, but the Wikipedia dumps contain malformed characters. You might see a 'Invalid UTF-8 byte sequence' error when running a Wukong job as a result.

To fix this, use `guard_encoding` in MungingUtils to filter out invalid characters before attempting to process them. `guard_encoding` replaces all invalid characters with '�'.

If you're piping things around on the command line and need to filter stuff there, pipe them through char_filter.rb.

If, for some reason, you need an invalid UTF-8 character, pretty much any single-byte character above \x79 will do. e.g:

    [1] pry(main)> char = "\x80"
    => "\x80"
    [2] pry(main)> char.encoding.name
    => "UTF-8"
    [3] pry(main)> char.valid_encoding?
    => false

[James Gray's blog](http://blog.grayproductions.net/articles/understanding_m17n) is really valuable for further reading on this.

## Dates
Date information should be formatted as follows:

    +----------+--------+--------------------------+-------------+
    | int      | int    | long or float            | int         |
    +----------+--------+--------------------------+-------------+
    | YYYYMMDD | HHMMSS | Seconds since Unix epoch | Day of week |
    +----------+--------+--------------------------+-------------+

Should always be in the UTC time zone.

Hours go from 0 to 23

Months go from 01 to 12

Day of week goes from 0 to 6 (Sunday to Saturday)
