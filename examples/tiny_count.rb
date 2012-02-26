mapper{|i|  i|->(l){ l.downcase.split(/\W+/).each{|w| emit(w) if !(w.size<3)} }}

reducer{|i| i|->(r){ emit [r.size,r[0]] } | to_tsv }
