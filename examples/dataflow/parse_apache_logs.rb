#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path("../lib", File.realdirpath(File.dirname(__FILE__))))
require 'wukong'

Settings.use(:commandline)
Settings.define :profiler, :default => nil
Settings.resolve!

require File.expand_path('../examples_helper', File.dirname(__FILE__))
require Pathname.path_to(:examples, 'dataflow/apache_log_line')

Wukong.dataflow(:parse_apache_logs) do
  doc <<-DOC
    Parses an apache log line into a structured model, emits it as JSON
  DOC

  source = ($0 == __FILE__) ? stdin : file_source(Pathname.path_to(:data, 'log/sample_apache_log.log'))
  set_input  :default, source
  set_output :dump,    stdout

  parser = map{|line| ApacheLogLine.make(line) or bad_record(line) }
  p input(:default)
  p parser
  p to_tsv
  p output(:dump)

  input(:default) >
    parser >
    to_tsv >
    output(:default)
end

# if ($0 == __FILE__)
#   flow_name = :parse_apache_logs
#   if Settings.profiler
#     require 'perftools'
#     Pathname(Settings.profiler).dirname.mkpath
#     PerfTools::CpuProfiler.start(Settings.profiler) do
#       Wukong::LocalRunner.run(Wukong.dataflow(flow_name), :default)
#     end
#   else
#     Wukong::LocalRunner.run(Wukong.dataflow(flow_name), :default)
#   end
#
#   # require 'jruby/profiler'
#   # profile_data = JRuby::Profiler.profile do
#   #   Wukong::LocalRunner.run(Wukong.dataflow(flow_name), :default)
#   # end
#   # profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
#   # profile_printer.printProfile($stderr)
#
#   # Wukong::LocalRunner.run(Wukong.dataflow(flow_name), :default)
# end
