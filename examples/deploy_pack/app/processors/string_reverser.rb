Wukong.processor(:string_reverser) do
  def process string
    yield string.reverse
  end
end
