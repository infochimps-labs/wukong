def in_groups_of arr, n
  grouped = []
  while ! arr.empty? do
    group = []
    n.times{ group << arr.shift }
    grouped << group
  end
  grouped
end

