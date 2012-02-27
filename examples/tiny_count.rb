mapper{|i|  i |->(l){ l.downcase.split(/\W+/).each{|w| emit(w) if w.size>2 }}
reducer{|i| i | counter |->(r){ emit r.reverse }|to_tsv }
