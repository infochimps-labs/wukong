# require 'rubygems'
# require 'faster_csv'
# module WukongUtils
#   #
#   # add a method exactly like +parse_csv+ but specifying a tab-separator
#   #
#   String.class_eval do
#     #
#     # Like the +parse_csv+ added by FasterCSV but specifying a tab-separator
#     #
#     def parse_tsv options={}
#       parse_csv options.merge( :col_sep => "\t" )
#     end
#   end
#
#   #
#   # add a method exactly like +to_csv+ but specifying a tab-separator
#   #
#   Array.class_eval do
#     #
#     # Like the +to_csv+ added by FasterCSV but specifying a tab-separator
#     #
#     def to_tsv options={}
#       to_csv options.merge( :col_sep => "\t" )
#     end
#   end
#
# end
