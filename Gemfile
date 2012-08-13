source 'http://rubygems.org'

gem   'configliere', ">= 0.4.15"
gem   'gorillib',    "~> 0.4.2",  :github => 'infochimps-labs/gorillib', :branch => 'version_1'

gem   'multi_json',  ">= 1.1"

gem   'extlib'
gem   'addressable'
gem   'htmlentities'
gem   'home_run',    :platform => [:mri, :rbx], :require=>'date'

# Only gems that you want listed as development dependencies in the gemspec
group :development do
  gem 'bundler',     "~> 1.1"
  gem 'rake'
  gem 'yard',        ">= 0.7"
  gem 'rspec',       ">= 2.8"
  gem 'jeweler',     ">= 1.6"
end

group :docs do
  gem 'RedCloth',    ">= 4.2",   :require => "redcloth"
  gem 'redcarpet',   ">= 2.1",   :platform => [:mri, :rbx]
  gem 'kramdown',                :platform => :jruby
end

# Gems for testing and coverage
group :test do
  gem 'simplecov',   ">= 0.5",   :platform => :ruby_19
  #
  gem 'oj',          ">= 1.2",   :platform => [:mri, :rbx]
  gem 'json',                    :platform => :jruby
end

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'perftools.rb',            :platform => :mri
  #
  gem 'guard',       ">= 1.0",   :platform => [:ruby_19]
  gem 'guard-rspec', ">= 0.6",   :platform => [:ruby_19]
  gem 'guard-yard',              :platform => [:ruby_19]
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9",  :platform => [:ruby_19]
  end
end
