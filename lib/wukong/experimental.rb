def Wu(&block)
  Wukong.class_eval{ def self.load_examples_helper() require File.expand_path("../../examples/examples_helper", File.dirname(__FILE__)) ; end }
  Wukong.instance_eval(&block)
  Wukong.run
end
