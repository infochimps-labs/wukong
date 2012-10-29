require 'gorillib'
require 'gorillib/data_munging'
require 'configliere'

S3_BUCKET = 'bigdata.chimpy.us'
S3_DATA_ROOT = "s3n://#{S3_BUCKET}/data"
HDFS_DATA_ROOT = '/data'

Settings.define :orig_data_root, default: HDFS_DATA_ROOT, description: "directory root for input data"
Settings.define :scratch_data_root, default: HDFS_DATA_ROOT, description: "directory root for scratch data"
Settings.define :results_data_root, default: HDFS_DATA_ROOT, description: "directory root for results data"
Settings.define :mini, description: 'Run in mini mode - operate inside the mini version of the specified universe',type: :boolean, default: false
Settings.define :universe, description: 'Universe to draw data from', finally: ->(c){ c.universe ||= (c.mini? ? "mini" : "full") }
Settings.define :pig_path, default: '/usr/local/bin/pig'
Settings.define :local, type: :boolean, default: false

def Settings.mini?; !! Settings.mini ; end # BANG BANG BANG
def Settings.wu_run_cmd; (local ? '--run=local' : '--run') ; end;

def dir_exists? (dir)
  if Settings.local
    return File.exists? dir
  else
    `hadoop fs -test -e #{dir}`
    return $?.exitstatus == 0
  end
end

def wukong(script, input, output, options={})
  input = Pathname.of(input)
  output = Pathname.of(output)
  if dir_exists? output
    puts "#{output} exists. Assuming that this job has already run..."
    return
  end
  opts = ['--rm']
  options.each_pair do |k,v|
    opts << "--#{k}=#{v}"
  end
  opts << input
  opts << output
  ruby(script, Settings.wu_run_cmd,*opts)
end

def wukong_xml(script, input, output, split_tag)
  wukong(script,input,output,{split_on_xml_tag: split_tag})
end

def pig(script_name, options={})
  cmd = Settings.pig_path
  options.each_pair do |k,v|
    v = Pathname.of(v) if v.is_a? Symbol
    if k.to_s.include? '_out' and dir_exists? v
      puts "#{v} already exists. Assuming that this job has already run..."
      return
    else
      cmd += " -param #{k.upcase}=#{v}"
    end
  end
  cmd += " #{script_name}"
  sh cmd
end
