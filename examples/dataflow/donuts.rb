Wukong.dataflow(:gotta_make_the_donuts) do
  input  :dough_circles, dough_hopper
  output :donut_box,     box(:capacity => 12)

  input(:dough_circles) >
    frier(:top_frier) >
    flipper >
    frier(:btm_frier) >
    cooling(:pre_glazer) >
    glazer >
    cooling(:ready) >
    output(:donut_box)
end
