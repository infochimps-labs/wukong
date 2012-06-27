Wukong.processor(:stratify) do
  def emit(record, output_label)
    output(output_label).process(record)
  end

  def process(user)
    case user.followers_count
    when nil          then emit(user, :blank)
    when    0..200    then emit(user, :low)
    when  200..20_000 then emit(user, :med)
    else                   emit(user, :hi)
    end
  end
end

Wukong.dataflow(:something) do

  input > stage(:splitty, stratify) do
    output(:low) > file('users_med')
  end
  stage(:splitty).output(:med) > file('users_med')
  stage(:splitty).output(:hi)  > file('users_hi')

  # or

  splitty = stratify
  input > splitty do
    output(:low) > file('users_med')
  end
  splitty.output(:med) > file('users_med')
  splitty.output(:hi)  > file('users_hi')

end
