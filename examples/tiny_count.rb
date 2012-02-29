mapper{|i| i |
  ->(l){ l.downcase.split(/\W+/) } |
  select{|w| w.size>2 } }

reducer{|i| i |
  counter |
  map(&:reverse) |
  to_tsv }
