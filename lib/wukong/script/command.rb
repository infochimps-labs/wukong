require 'bundler'

Bundler.setup(:default, :script)

require 'configliere'
require 'gorillib/system/runner'
require 'gorillib/string/inflections'

Bundler.setup :script
Settings.use :commandline
