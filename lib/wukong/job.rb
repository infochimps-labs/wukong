module Wukong
  #
  #
  #
  #
  class Job < Wukong::Graph

    def to_s
      ['<job', handle,
        "chain={#{chain.join(' | ')}}"
      ].join(' ')+'>'
    end
  end

  def self.job(handle, *args, &block)
    @jobs ||= Hash.new
    @jobs[handle] ||= Job.new(handle, *args, &block)
  end
end
