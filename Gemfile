source 'https://rubygems.org'

# Developers may want to run the following (fixing the paths):
#
#   bundle config local.vayacondios-client ~/code/vayacondios
#   bundle config local.gorillib           ~/code/gorillib
#

gemspec

gem "gorillib", github: 'infochimps-labs/gorillib', branch: 'master'

group :script do
  gem 'childprocess', '~> 0.3.8'
end

group :streaming do
  gem "vayacondios-client", github: 'infochimps-labs/vayacondios', branch: 'master'
end
