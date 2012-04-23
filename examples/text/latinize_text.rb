load_examples_helper
require Wukong.path_to(:examples, 'text/pig_latin')

mapper do |input|
  input | map{|line| Wukong.latinize(line) }
end
