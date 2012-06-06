
# TODO: a flow with splits and stuff

# parsed = map{|line| ApacheLogLine.make(line) }
#
# input(:default) > parsed
#
# parsed > split.into(
#   to_json > output(:dump, stdout),
#   to_tsv  > output(:tsv, file_sink(Pathname.path_to(:tmp, 'foo.tsv')))
#   )
