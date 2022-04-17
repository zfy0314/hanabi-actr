(clear-all)

(define-model hanabi
(sgp :v t :esc t :egs 1 :show-focus f :ul t :ult t :needs-mouse t)

(chunk-type goal-type state hints hits)
(chunk-type (card-loc (:include visual-location)) color rank owner index count)
(chunk-type (card-obj (:include visual-object))   color rank owner index count)
(chunk-type (knowledge-loc (:include visual-location)) blue green red white yellow one two three four five color rank hinted index owner)
(chunk-type (knowledge-obj (:include visual-object))   blue green red white yellow one two three four five color rank hinted index owner)

(chunk-type rank rank next key)
(chunk-type index obj key)
(chunk-type hint color rank)

(add-dm
   (goal isa goal-type state start)
   (zero  isa rank rank zero  next one   key "0")
   (one   isa rank rank one   next two   key "1")
   (two   isa rank rank two   next three key "2")
   (three isa rank rank three next four  key "3")
   (four  isa rank rank four  next five  key "4")
   (five  isa rank rank four  next nil   key "5")
   (c1 isa index obj blue   key "1")
   (c2 isa index obj green  key "2")
   (c3 isa index obj red    key "3")
   (c4 isa index obj white  key "4")
   (c5 isa index obj yellow key "5")
)

(P find-partner-card
   =goal>
      isa         goal-type
      state       start
==>
   =goal>
      state       attend-partner
   +visual-location>
      isa         card-loc
      :attended   nil
      kind        card-obj
      owner       partner
)

(P attend-partner-card
   =goal>
      isa         goal-type
      state       attend-partner
   =visual-location>
==>
   =goal>
      state       test-partner
   +visual>
      cmd         move-attention
      screen-pos  =visual-location
)

(P test-partner-card
   =goal>
      isa         goal-type
      state       test-partner
   =visual>
      isa         card-obj
      owner       partner
      color       =c
      rank        =r
==>
   =goal>
      state       check-board
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       board
      color       =c
   +retrieval>
      isa         rank
      next        =r
   +imaginal>
      isa         hint
      color       =c
      rank        =r
)

(P attend-board
   =goal>
      isa         goal-type
      state       check-board
   =visual-location>
==>
   =goal>
      state       check-partner
   +visual>
      cmd         move-attention
      screen-pos  =visual-location
)

(P hint-playable-color
   =goal>
      isa         goal-type
      state       check-partner
   =visual>
      isa         card-obj
      owner       board
      color       =c
      rank        =rb
   =retrieval>
      isa         rank
      rank        =rb
   =imaginal>
      isa         hint
      color       =c
==>
   =goal>
      state       hint-to-play-color
   -visual>
   +retrieval>
      isa         index
      obj         =c
)

(P not-playable
   =goal>
      isa         goal-type
      state       check-partner
   =visual>
      isa         card-obj
      owner       board
      rank        =rb
   =retrieval>
      isa         rank
    - rank        =rb
==>
   =goal>
      state       start
   -retrieval>
   -visual-location>
   -imaginal>
)

(P hint-color
   =goal>
      isa         goal-type
      state       hint-to-play-color
==>
   =goal>
      state       respond2
   +manual>
      cmd         press-key
      key         "C"
)

(P press-second-key
   =goal>
      isa         goal-type
      state       respond2
   ?manual>
      state       free
   =retrieval>
      key         =key
==>
   =goal>
      state       done
   +manual>
      cmd         press-key
      key         =key
)

(goal-focus goal)
)
