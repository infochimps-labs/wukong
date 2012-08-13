source 'http://rubygems.org'

gem   'configliere', ">= 0.4.15"
gem   'gorillib',    ">= 0.4",  :github => 'infochimps-labs/gorillib', :branch => 'version_1'

gem   'multi_json',  ">= 1.1"

gem   'extlib'
gem   'addressable'
gem   'htmlentities'
gem   'home_run',               :platform => [:ruby], :require=>'date'

# Only gems that you want listed as development dependencies in the gemspec
group :development do
  gem 'bundler',     "~> 1.1"
  gem 'rake',                   :require => false
  gem 'yard',        ">= 0.7",  :require => false
  gem 'rspec',       ">= 2.8",  :require => false
  gem 'jeweler',     ">= 1.6",  :require => false
end

group :docs do
  gem 'RedCloth',    ">= 4.2",  :require => "redcloth"
  gem 'redcarpet',   ">= 2.1",  :platform => [:ruby]
  gem 'kramdown',               :platform => [:jruby]
end

# Gems for testing and coverage
group :test do
  gem 'simplecov',   ">= 0.5",  :platform => [:ruby_19],   :require => false
  gem 'json',                   :require => false
  gem 'oj',          ">= 1.2",  :platform => [:ruby_19]
end

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'perftools.rb',           :platform => :mri
  #
  gem 'guard',       ">= 1.0",  :platform => [:ruby_19]
  gem 'guard-rspec', ">= 0.6",  :platform => [:ruby_19]
  gem 'guard-yard',             :platform => [:ruby_19]
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9", :platform => [:ruby_19]
  end
end
