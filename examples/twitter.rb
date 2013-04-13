Wukong.dataflow(:twitter) do
  from_json | reject { |obj| obj["delete"]  } |
    [
     
end
