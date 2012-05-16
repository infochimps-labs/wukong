module Wukong
  class Counter < Wukong::Processor
    field :count,       Integer, :doc => 'count of records this run'

    def setup
      super
      reset!
    end

    def reset!
      self.count = 0
    end

    def beg_group(*args)
      reset!
    end

    def end_group(key)
      emit( [key, count] )
    end

    def process(record)
      @count += 1
    end
  end

  class GroupArrays < Wukong::Processor
    def beg_group
      @records = []
    end

    def end_group(key)
      emit(key, @records)
    end

    def process(record)
      @records << record
    end
  end

  class Group < Wukong::Processor
    def start(key, *vals)
      @key = key
      next_stage.tell(:beg_group, @key)
    end

    def end_group
      next_stage.tell(:end_group, @key)
    end

    def process( (key, *vals) )
      start(key, *vals) unless defined?(@key)
      if key != @key
        end_group
        start(key, *vals)
      end
      emit( [key, *vals] )
    end

    def finally
      end_group
      super()
    end
  end

end
