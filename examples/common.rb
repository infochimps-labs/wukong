require_relative '../lib/wu/munging'

Pathname.register_paths(
  rawd: File.expand_path('../data', File.dirname(__FILE__))
)
