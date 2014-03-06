 module Wukong
   module Streamer
     class Reducer < Wukong::Streamer::ListReducer

       def finalize &block
         reduce @values, &block
       end
     end

   end
end
