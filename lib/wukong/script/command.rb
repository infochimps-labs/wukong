require 'bundler'

Bundler.setup(:default, :script)

require 'configliere'
require 'gorillib/system/runner'

Bundler.setup :script
Settings.use :commandline
