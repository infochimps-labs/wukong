module Wukong

  def self.mapper(flow_name=:mapper, &block)
    flow(flow_name) do
      input = source(:stdin)
      instance_exec(input, &block) | stdout
    end
  end

  def self.reducer(flow_name=:reducer, &block)
    flow(flow_name) do
      input = source(:stdin) | group
      instance_exec(input, &block) | stdout
    end
  end

end
