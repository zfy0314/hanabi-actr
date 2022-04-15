(clear-all)

(define-model hanabi
(sgp :v nil :esc t :lf 0.3 :bll 0.5 :ans 0.5 :rt 1.1 :ncnar nil :trace-detail low)
(sgp :v nil :esc t :egs 1 :show-focus f :ul t :ult t :needs-mouse t)

(chunk-type goal-type state hints hits)
(chunk-type (card-loc (:include visual-location)) color rank owner index)
(chunk-type (card-obj (:include visual-object))   color rank owner index)
(chunk-type (knowledge-loc (:include visual-location)) blue green red white yellow one two three four five index onwer)
(chunk-type (knowledge-obj (:include visual-object))   blue green red white yellow one two three four five index onwer)
(add-dm
   (goal isa goal-type state play)
   (play) (play2) (done)
)

(P play-first1
   =goal>
      isa         goal-type
      state       play
   ?manual>
      state       free
==>
   =goal>
      state       play2
   +manual>
      cmd         press-key
      key         "P"
)

(P play-first2
   =goal>
      isa         goal-type
      state       play2
   ?manual>
      state       free
==>
   =goal>
      state       play
   +manual>
      cmd         press-key
      key         "1"
)

(goal-focus goal)
)
