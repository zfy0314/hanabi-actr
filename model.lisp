(clear-all)

(define-model hanabi
(sgp :v t :esc t :egs 1 :show-focus f :ul t :ult t :needs-mouse t)

(chunk-type (card-loc (:include visual-location)) color rank owner index count)
(chunk-type (card-obj (:include visual-object))   color rank owner index count)
(chunk-type (knowledge-loc (:include visual-location)) blue green red white yellow one two three four five color rank hinted index owner)
(chunk-type (knowledge-obj (:include visual-object))   blue green red white yellow one two three four five color rank hinted index owner)

(chunk-type goal-type
   state misc1 misc2 misc3                ; general control state
   hints hits blue green red yellow white ; game state
   s1 s2 s3 s4 s5 s6 s7                   ; if attempted each strategy
)
(chunk-type imaginal-type blue green red yellow white one two three four five index key)

(add-dm
   (goal isa goal-type state start)
)



; helper
(P h-attend-success
   =goal>
      isa         goal-type
      state       attend
      misc1       =n
   =visual-location>
==>
   =goal>
      state       =n
   +visual>
      cmd         move-attention
      screen-pos  =visual-location
)

(P h-attend-failure
   =goal>
      isa         goal-type
      state       attend
      misc2       =n
   ?visual-location>
      buffer      failure
==>
   =goal>
      state       =n
)



; reasonable strategies
(P s-play-definitely-playable
   =goal>
      isa         goal-type
      state       start
      s1          t
==>
   =goal>
      state       attend
      misc1       play-definitely-playable-test-my
      misc2       play-definitely-playable-failure
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
   -imaginal>
)

(P s-play-potentially-playable
   =goal>
      isa         goal-type
      state       start
      s2          t
==>
   =goal>
      state       play-potentially-playable
   +imaginal>
      isa         imaginal-type
      blue        t
      green       t
      red         t
      white       t
      yellow      t
)

(P s-play-potentially-playable-only-when-low-hits
   =goal>
      isa         goal-type
      state       start
      s2          t
    < hits        2
==>
   =goal>
      state       play-potentially-playable
   +imaginal>
      isa         imaginal-type
      blue        t
      green       t
      red         t
      white       t
      yellow      t
)

(P s-play-just-hinted-right
   =goal>
      isa         goal-type
      state       start
      s3          t
==>
   =goal>
      state       attend
      misc1       play-just-hinted-test-my
      misc2       play-just-hinted-failure
      misc3       play-just-hinted-right-init
   +imaginal>
      one         t
      two         t
      three       t
      four        t
      five        t
      blue        t
      green       t
      red         t
      white       t
      yellow      t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      hinted      t
      screen-y    highest
)

; (P s-discard-useless
;    =goal>
;       isa         goal-type
;       state       start
;     < hint        8
; ==>
;    =goal>
;       state       discard-useless-0
; )
;
; (P s-discard-least-info
;    =goal>
;       isa         goal-type
;       state       start
;     < hint        8
; ==>
;    =goal>
;       state       discard-least-info-0
; )
;
; (P s-discard
;    =goal>
;       isa         goal-type
;       state       start
;     < hint        8
; ==>
;    =goal>
;       state       discard-0
; )
;
; (P s-hint-to-play
;    =goal>
;       isa         goal-type
;       state       start
;     > hint        0
; ==>
;    =goal>
;       state       hint-to-play-0
; )

; (P s-hint-to-discard
; )
;
; (P s-hint-for-info
; )


; play-definitely-playable
(P p-play-definitely-playable-init
   =goal>
      isa         goal-type
      state       play-definitely-playable-init
==>
   =goal>
      state       attend
      misc1       play-definitely-playable-test-my
      misc2       play-definitely-playable-failure
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
    > screen-y    current
)

(P p-play-definitely-playable-failure
   =goal>
      isa         goal-type
      state       play-definitely-playable-failure
==>
   =goal>
      state       start
      s1          nil
   -visual-location>
   -imaginal>
)

(P p-play-definitely-playable-test-my-full-knowledge-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      rank        =r
    - rank        nil
      index       =i
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
      =c          =s
==>
   =goal>
      state       play
   +imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-definitely-playable-test-my-full-knowledge-failure
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      rank        =r
    - rank        nil
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
    - =c          =s
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-unknown-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        nil
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-blue-impossible
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - blue        t
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
==>
   =goal>
      state       play-definitely-playable-test-my-green
   =visual>
)

(P p-play-definitely-playable-test-my-blue-possible-good
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      blue        t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
      blue        =s
==>
   =goal>
      state       play-definitely-playable-test-my-green
   =visual>
)

(P p-play-definitely-playable-test-my-blue-possible-bad
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      blue        t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
    - blue        =s
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-green-impossible
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - green       t
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-green
==>
   =goal>
      state       play-definitely-playable-test-my-red
   =visual>
)

(P p-play-definitely-playable-test-my-green-possible-good
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      green       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-green
      blue        =s
==>
   =goal>
      state       play-definitely-playable-test-my-red
   =visual>
)

(P p-play-definitely-playable-test-my-green-possible-bad
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      green       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-green
    - green       =s
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-red-impossible
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - red         t
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-red
==>
   =goal>
      state       play-definitely-playable-test-my-white
   =visual>
)

(P p-play-definitely-playable-test-my-red-possible-good
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      red         t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-red
      red         =s
==>
   =goal>
      state       play-definitely-playable-test-my-white
   =visual>
)

(P p-play-definitely-playable-test-my-red-possible-bad
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      red         t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-red
    - red         =s
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-white-impossible
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - white       t
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-white
==>
   =goal>
      state       play-definitely-playable-test-my-yellow
   =visual>
)

(P p-play-definitely-playable-test-my-white-possible-good
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      white       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-white
      white       =s
==>
   =goal>
      state       play-definitely-playable-test-my-yellow
   =visual>
)

(P p-play-definitely-playable-test-my-white-possible-bad
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      white       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-white
    - white       =s
==>
   =goal>
      state       play-definitely-playable-init
)

(P p-play-definitely-playable-test-my-yellow-impossible
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - yellow      t
      index       =i
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-yellow
==>
   =goal>
      state       play
   +imaginal>
      isa         imaginal-type
      key         =i
   =visual>
)

(P p-play-definitely-playable-test-my-yellow-possible-good
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      yellow      t
      index       =i
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-yellow
      yellow      =s
==>
   =goal>
      state       play
   +imaginal>
      isa         imaginal-type
      key         =i
   =visual>
)

(P p-play-definitely-playable-test-my-yellow-possible-bad
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      yellow      t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my-yellow
    - yellow      =s
==>
   =goal>
      state       play-definitely-playable-init
)

; play-potentially-playable
(P p-play-potentially-playable-failure
   =goal>
      isa         goal-type
      state       play-potentially-playable
   =imaginal>
      isa         imaginal-type
      blue        nil
      green       nil
      red         nil
      white       nil
      yellow      nil
==>
   =goal>
      state       start
      s2          nil
   -visual-location>
   -imaginal>
)

(P p-play-potentially-playable-search-success
   =goal>
      isa         goal-type
      state       play-potentially-playable-success
   =visual>
      isa         knowledge-obj
      index       =i
==>
   =goal>
      state       play
   +imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-potentially-playable-search-failure
   =goal>
      isa         goal-type
      state       play-potentially-playable-failure
      misc3       =c
   =imaginal>
==>
   =goal>
      state       play-potentially-playable
   =imaginal>
      isa         imaginal-type
      =c          nil
)

(P p-play-potentially-playable-blue
   =goal>
      isa         goal-type
      state       play-potentially-playable
      blue        =r
   !bind! =s (- =r 1)
   =imaginal>
      isa         imaginal-type
      blue        t
==>
   =goal>
      state       attend
      misc1       play-potentially-playable-success
      misc2       play-potentially-playable-failure
      misc3       blue
   =imaginal>
      isa         imaginal-type
      blue        t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      blue        t
      rank        =s
)

(P p-play-potentially-playable-green
   =goal>
      isa         goal-type
      state       play-potentially-playable
      green       =r
   !bind! =s (- =r 1)
   =imaginal>
      isa         imaginal-type
      green       t
==>
   =goal>
      state       attend
      misc1       play-potentially-playable-success
      misc2       play-potentially-playable-failure
      misc3       green
   =imaginal>
      isa         imaginal-type
      green       t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      green       t
      rank        =s
)

(P p-play-potentially-playable-red
   =goal>
      isa         goal-type
      state       play-potentially-playable
      red         =r
   !bind! =s (- =r 1)
   =imaginal>
      isa         imaginal-type
      red         t
==>
   =goal>
      state       attend
      misc1       play-potentially-playable-success
      misc2       play-potentially-playable-failure
      misc3       red
   =imaginal>
      isa         imaginal-type
      red       t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      red         t
      rank        =s
)

(P p-play-potentially-playable-white
   =goal>
      isa         goal-type
      state       play-potentially-playable
      white       =r
   !bind! =s (- =r 1)
   =imaginal>
      isa         imaginal-type
      white       t
==>
   =goal>
      state       attend
      misc1       play-potentially-playable-success
      misc2       play-potentially-playable-failure
      misc3       white
   =imaginal>
      isa         imaginal-type
      white       t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      white       t
      rank        =s
)

(P p-play-potentially-playable-yellow
   =goal>
      isa         goal-type
      state       play-potentially-playable
      yellow      =r
   !bind! =s (- =r 1)
   =imaginal>
      isa         imaginal-type
      yellow      t
==>
   =goal>
      state       attend
      misc1       play-potentially-playable-success
      misc2       play-potentially-playable-failure
      misc3       yellow
   =imaginal>
      isa         imaginal-type
      yellow      t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      yellow      t
      rank        =s
)

; play-just-hinted
(P p-play-just-hinted-not-found
   =goal>
      isa         goal-type
      state       play-just-hinted-failure
==>
   =goal>
      state       start
      s3          nil
   -visual-location>
   -imaginal>
)

(P p-play-just-hinted-right-init
   =goal>
      isa         goal-type
      state       play-just-hinted-right-init
==>
   =goal>
      state       attend
      misc1       play-just-hinted-test-my
      misc2       play-just-hinted-failure
      misc3       play-just-hinted-right-init
   +imaginal>
      one         t
      two         t
      three       t
      four        t
      five        t
      blue        t
      green       t
      red         t
      white       t
      yellow      t
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      hinted      t
      screen-y    highest
    < screen-y    current
)

(P p-play-just-hinted-check-colors-failed
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      misc3       =fallback
   =imaginal>
      isa         imaginal-type
      blue        nil
      green       nil
      red         nil
      white       nil
      yellow      nil
==>
   =goal>
      state       =fallback
   -imaginal>
)

(P p-play-just-hinted-check-ranks-failed
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      misc3       =fallback
   =imaginal>
      isa         imaginal-type
      one         nil
      two         nil
      three       nil
      four        nil
      five        nil
==>
   =goal>
      state       =fallback
   -imaginal>
)

(P p-play-just-hinted-check-blue-success
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      index       =i
      blue        t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      blue        =s
   =imaginal>
      isa         imaginal-type
      blue        t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-blue-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      blue        t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - blue        =s
   =imaginal>
      isa         imaginal-type
      blue        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      blue        nil
   =visual>
)

(P p-play-just-hinted-check-blue-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - blue        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      blue        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      blue        nil
   =visual>
)

(P p-play-just-hinted-check-green-success
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      index       =i
      green       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      green       =s
   =imaginal>
      isa         imaginal-type
      green       t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-green-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      green       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      - green     =s
   =imaginal>
      isa         imaginal-type
      green       t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      green       nil
   =visual>
)

(P p-play-just-hinted-check-green-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - green       t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      green       t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      green       nil
   =visual>
)


(P p-play-just-hinted-check-red-success
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      index       =i
      red         t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      red         =s
   =imaginal>
      isa         imaginal-type
      red         t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-white-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      white       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - white       =s
   =imaginal>
      isa         imaginal-type
      white        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      white       nil
   =visual>
)

(P p-play-just-hinted-check-white-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - white       t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      white       t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      white       nil
   =visual>
)


(P p-play-just-hinted-check-yellow-success
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      index       =i
      yellow      t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      yellow      =s
   =imaginal>
      isa         imaginal-type
      yellow      t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-yellow-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      yellow      t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - yellow      =s
   =imaginal>
      isa         imaginal-type
      yellow      t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      yellow      nil
   =visual>
)

(P p-play-just-hinted-check-yellow-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - yellow      t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      yellow      t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      yellow      nil
   =visual>
)

(P p-play-just-hinted-check-one-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      index       =i
      one         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      =c          0
   =imaginal>
      isa         imaginal-type
      one         t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
   =visual>
)

(P p-play-just-hinted-check-one-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      one         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - =c          0
   =imaginal>
      isa         imaginal-type
      one         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      one         nil
   =visual>
)

(P p-play-just-hinted-check-one-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - one         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      one         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      one         nil
   =visual>
)

(P p-play-just-hinted-check-two-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      index       =i
      two         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      =c          1
   =imaginal>
      isa         imaginal-type
      two         t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-two-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      two         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - =c          1
   =imaginal>
      isa         imaginal-type
      two         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      two         nil
   =visual>
)

(P p-play-just-hinted-check-two-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - two         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      two         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      two         nil
   =visual>
)

(P p-play-just-hinted-check-three-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      index       =i
      three       t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      =c          2
   =imaginal>
      isa         imaginal-type
      three       t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-three-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      three       t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - =c          2
   =imaginal>
      isa         imaginal-type
      three       t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      three       nil
   =visual>
)

(P p-play-just-hinted-check-three-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - three       t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      three       t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      three       nil
   =visual>
)

(P p-play-just-hinted-check-four-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      index       =i
      four        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      =c          3
   =imaginal>
      isa         imaginal-type
      four        t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-four-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      four        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - =c          3
   =imaginal>
      isa         imaginal-type
      four        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      four        nil
   =visual>
)

(P p-play-just-hinted-check-four-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - four        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      four        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      four        nil
   =visual>
)


(P p-play-just-hinted-check-five-success
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      index       =i
      five        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      =c          4
   =imaginal>
      isa         imaginal-type
      five        t
==>
   =goal>
      state       play
   =imaginal>
      isa         imaginal-type
      key         =i
)

(P p-play-just-hinted-check-five-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      color       =c
    - color       nil
      five        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - =c          4
   =imaginal>
      isa         imaginal-type
      five        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      five        nil
   =visual>
)

(P p-play-just-hinted-check-five-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - five        t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      five        t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      five        nil
   =visual>
)





; feedback for utility learning
(P inform-play-unsuccessful
   =goal>
      isa goal-type
      state play-unsuccessful
==>
   =goal>
      state done
)

(P inform-play-successful
   =goal>
      isa goal-type
      state play-successful
==>
   =goal>
      state done
)

(P inform-discard-useless
   =goal>
      isa goal-type
      state discard-useless
==>
   =goal>
      state done
)

(P inform-discard-neutral
   =goal>
      isa goal-type
      state discard-neutral
==>
   =goal>
      state done
)

(P inform-discard-playable
   =goal>
      isa goal-type
      state discard-playable
==>
   =goal>
      state done
)



; pressing keys
(P press-hint-color
   =goal>
      isa         goal-type
      state       hint-color
==>
   =goal>
      state       respond2
   +manual>
      cmd         press-key
      key         "C"
)

(P press-hint-rank
   =goal>
      isa         goal-type
      state       hint-rank
==>
   =goal>
      state       respond2
   +manual>
      cmd         press-key
      key         "R"
)

(P press-play
   =goal>
      isa         goal-type
      state       play
==>
   =goal>
      state       respond2
   +manual>
      cmd         press-key
      key         "P"
)

(P press-discard
   =goal>
      isa         goal-type
      state       discard
==>
   =goal>
      state       respond2
   +manual>
      cmd         press-key
      key         "D"
)

(P press-second-key
   =goal>
      isa         goal-type
      state       respond2
   ?manual>
      state       free
   =imaginal>
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
