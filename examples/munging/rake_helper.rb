require 'gorillib'
require 'gorillib/data_munging'

S3_DATA_ROOT = 's3n://bigdata.chimpy.us/data'
HDFS_DATA_ROOT = '/data'

Settings.define :orig_data_root, default: S3_DATA_ROOT, description: "directory root for input data"
Settings.define :scratch_data_root, default: HDFS_DATA_ROOT, description: "directory root for scratch data"
Settings.define :results_data_root, default: HDFS_DATA_ROOT, description: "directory root for results data"
Settings.define :universe, description: 'Universe to draw data from', finally: ->(c){ c.universe ||= (c.mini? ? "mini" : "full") }
Settings.define :pig_path, default: '/usr/local/bin/pig'

def wukong(script, input, output)
  input = Settings.in_data_root + Pathname.of(input)
  output = Settings.out_data_root + Pathname.of(output)
  ruby(script, "--run", input, output)
end

def wukong_xml(script, input, output, split_tag)
  input = Settings.in_data_root + Pathname.of(input)
  output = Settings.out_data_root + Pathname.of(output)
  ruby(script,"--run","--split_on_xml_tag=#{split_tag}", input, output)
end

def pig(script_name, options={})
  cmd = Settings.pig_path
  options.each_pair do |k,v|
      v = Pathname.of(v) if v.is_a? Symbol
      cmd += " -param #{k}=#{v}"
  end
  cmd += " #{script_name}"
  sh cmd
end
