module Wukong
  class Job
    attr_reader :tasks

    def task(*args, &block)
      Task.new(*args, &block)
    end
  end

  class Task
  end

  def self.job(*args, &block)
    Job.new(*args, &block)
  end
end
