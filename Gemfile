source "http://rubygems.org"

gem 'gorillib',       "~> 0.1.8"
gem 'configliere',    "~> 0.4.8"
gem 'icss',           :git => 'git://github.com/infochimps-labs/icss.git'

gem 'multi_json',     "~> 1.1"
gem 'yajl-ruby',      "~> 1.1", :platform => :mri
gem 'json',                     :platform => :jruby
gem 'log4r'

group :development do
  gem 'bundler',      "~> 1"
  gem 'jeweler',      "~> 1.6"
  gem 'log_buddy'
  gem 'addressable'
  gem 'htmlentities'
  gem 'pry'
end

group :docs do
  gem 'yard',         "~> 0.7"
  gem 'RedCloth',     "~> 4.2"
  gem 'redcarpet',    "~> 2.1"
end

group :test do
  gem 'rspec',        "~> 2.8"
  gem 'simplecov',    "~> 0.6", :platform => :ruby_19

  gem  'guard',       "~> 1.0"
  gem  'guard-rspec', "~> 0.6"
  gem  'guard-yard'

  if RUBY_PLATFORM.include?('darwin')
    gem 'growl',      "~> 1"
    gem 'rb-fsevent', "~> 0.9"
  end
end
