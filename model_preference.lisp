(clear-all)

(define-model hanabi
(sgp :v t :esc t :egs 0.5 :show-focus f :ul t :ult t :needs-mouse t :ignore-buffers (visual visual-location imaginal goal) :seed (2022 426))


(chunk-type (card-loc (:include visual-location)) color rank owner index count)
(chunk-type (card-obj (:include visual-object))   color rank owner index count)
(chunk-type (knowledge-loc (:include visual-location)) blue green red white yellow one two three four five color rank hinted index owner)
(chunk-type (knowledge-obj (:include visual-object))   blue green red white yellow one two three four five color rank hinted index owner)

(chunk-type goal-type
   state misc1 misc2 misc3 misc4          ; general control state
   hints hits blue green red yellow white ; game state
   s1 s2 s3 s4 s5 s6 s7                   ; if attempted each strategy
)
(chunk-type imaginal-type blue green red yellow white one two three four five key)

(chunk-type color-iter prev next cindex)
(chunk-type rank-iter prev next rindex)

(add-dm
   (goal isa goal-type state start)
   (c0 isa color-iter prev nil   next blue   cindex 1)
   (c1 isa color-iter prev blue  next green  cindex 2)
   (c2 isa color-iter prev green next red    cindex 3)
   (c3 isa color-iter prev red   next white  cindex 4)
   (c4 isa color-iter prev white next yellow cindex 5)
   (r0 isa rank-iter prev zero  next one   rindex 0)
   (r1 isa rank-iter prev one   next two   rindex 1)
   (r2 isa rank-iter prev two   next three rindex 2)
   (r3 isa rank-iter prev three next four  rindex 3)
   (r4 isa rank-iter prev four  next five  rindex 4)
   (r5 isa rank-iter prev five  next nil   rindex 5)
)



;; Helper Functions ;;

; finding some visual location
; start by requesting a visual location, and set goal state to attend, misc1 to
; the state for successfully finding a visual location, misc2 to the state for
; failure
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

;; Reasonable Strategies ;;

; find and play a card that is certainly playable
(P s-play-definitely-playable-left
   =goal>
      isa         goal-type
      state       start
      s1          t
==>
   =goal>
      state       attend
      misc1       play-definitely-playable-test-my
      misc2       play-definitely-playable-failure
      misc3       play-definitely-playable-init-left
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
   +retrieval>
      isa         color-iter
      next        blue
)

; (P s-play-definitely-playable-right
;    =goal>
;       isa         goal-type
;       state       start
;       s1          t
; ==>
;    =goal>
;       state       attend
;       misc1       play-definitely-playable-test-my
;       misc2       play-definitely-playable-failure
;       misc3       play-definitely-playable-init-right
;    +visual-location>
;       isa         knowledge-loc
;       kind        knowledge-obj
;       owner       model
;       screen-y    highest
;    +retrieval>
;       isa         color-iter
;       next        blue
; )

; find and play a card that has been hinted in the past and is potentially playable
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

; find and play a card that has been hinted recently and is potentially playable
; if there are more than one card corresponds to the hint, play the right-most
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
      misc3       play-just-hinted-init-right
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

; (P s-play-just-hinted-left
;    =goal>
;       isa         goal-type
;       state       start
;       s3          t
; ==>
;    =goal>
;       state       attend
;       misc1       play-just-hinted-test-my
;       misc2       play-just-hinted-failure
;       misc3       play-just-hinted-init-left
;    +imaginal>
;       one         t
;       two         t
;       three       t
;       four        t
;       five        t
;       blue        t
;       green       t
;       red         t
;       white       t
;       yellow      t
;    +visual-location>
;       isa         knowledge-loc
;       kind        knowledge-obj
;       owner       model
;       hinted      t
;       screen-y    lowest
; )

; find and discard a card that is definitely not playable
(P s-discard-useless-left
   =goal>
      isa         goal-type
      state       start
    < hints       8
      s4          t
==>
   =goal>
      state       attend
      misc1       discard-useless-test-my
      misc2       discard-useless-failure
      misc3       discard-useless-init-left
   +imaginal>
      yellow      5
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
   +retrieval>
      isa         color-iter
      next        blue
)

; (P s-discard-useless-right
;    =goal>
;       isa         goal-type
;       state       start
;     < hints       8
;       s4          t
; ==>
;    =goal>
;       state       attend
;       misc1       discard-useless-test-my
;       misc2       discard-useless-failure
;       misc3       discard-useless-init-right
;    +imaginal>
;       yellow      5
;    +visual-location>
;       isa         knowledge-loc
;       kind        knowledge-obj
;       owner       model
;       screen-y    highest
;    +retrieval>
;       isa         color-iter
;       next        blue
; )

; find and discard a card that is never hinted before (from old to new)
(P s-discard-unhinted-left
   =goal>
      isa         goal-type
      state       start
    < hints       8
      s5          t
==>
   =goal>
      state       attend
      misc1       discard-unhinted-success
      misc2       discard-unhinted-not-found
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      color       nil
      rank        nil
      screen-y    lowest
)

; (P s-discard-unhinted-right
;    =goal>
;       isa         goal-type
;       state       start
;     < hints       8
;       s5          t
; ==>
;    =goal>
;       state       attend
;       misc1       discard-unhinted-success
;       misc2       discard-unhinted-not-found
;    +visual-location>
;       isa         knowledge-loc
;       kind        knowledge-obj
;       owner       model
;       color       nil
;       rank        nil
;       screen-y    highest
; )

; discard a card at random
(P s-discard-random
   =goal>
      isa         goal-type
      state       start
    < hints       8
==>
   =goal>
      state       attend
      misc1       discard-random
      misc2       start
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
)

; give an unambiguous hint to the partner to play a card
(P s-hint-to-play-right
   =goal>
      isa         goal-type
      state       start
    > hints       0
      s6          t
==>
   =goal>
      state       attend
      misc1       hint-to-play-test-partner
      misc2       hint-to-play-failure
      misc3       hint-to-play-init-right
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
      screen-y    highest
)

; (P s-hint-to-play-left
;    =goal>
;       isa         goal-type
;       state       start
;     > hints       0
;       s6          t
; ==>
;    =goal>
;       state       attend
;       misc1       hint-to-play-test-partner
;       misc2       hint-to-play-failure
;       misc3       hint-to-play-init-left
;    +visual-location>
;       isa         card-loc
;       kind        card-obj
;       owner       partner
;       screen-y    lowest
; )

; hint a card at random
(P s-hint-random
   =goal>
      isa         goal-type
      state       start
    = hints       8
==>
   =goal>
      state       attend
      misc1       hint-random
      misc2       start
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
)

; (P s-hint-to-discard
; )
;
; (P s-hint-for-info
; )


; play-definitely-playable
(P p-play-definitely-playable-init-left
   =goal>
      isa         goal-type
      state       play-definitely-playable-init-left
==>
   =goal>
      state       attend
      misc1       play-definitely-playable-test-my
      misc2       play-definitely-playable-failure
      misc3       play-definitely-playable-init-left
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
    > screen-y    current
   +retrieval>
      isa         color-iter
      next        blue
)

(P p-play-definitely-playable-init-right
   =goal>
      isa         goal-type
      state       play-definitely-playable-init-right
==>
   =goal>
      state       attend
      misc1       play-definitely-playable-test-my
      misc2       play-definitely-playable-failure
      misc3       play-definitely-playable-init-right
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    highest
    < screen-y    current
   +retrieval>
      isa         color-iter
      next        blue
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
      misc3       =fallback
    - =c          =s
==>
   =goal>
      state       =fallback
)

(P p-play-definitely-playable-test-my-unknown-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        nil
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
      misc3       =fallback
==>
   =goal>
      state       =fallback
)

(P p-play-definitely-playable-test-my-color-impossible
   =retrieval>
      isa         color-iter
      next        =c
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
    - =c          t
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
==>
   =goal>
      state       play-definitely-playable-test-my
   =visual>
   +retrieval>
      isa         color-iter
      prev        =c
)

(P p-play-definitely-playable-test-my-color-possible-good
   =retrieval>
      isa         color-iter
      next        =c
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      =c          t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
      =c          =s
==>
   =goal>
      state       play-definitely-playable-test-my
   =visual>
   +retrieval>
      isa         color-iter
      prev        =c
)

(P p-play-definitely-playable-test-my-color-possible-bad
   =retrieval>
      isa         color-iter
      next        =c
   =visual>
      isa         knowledge-obj
      owner       model
      color       nil
    - rank        nil
      rank        =r
      =c          t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
    - =c          =s
      misc3       =fallback
==>
   =goal>
      state       =fallback
)

(P p-play-definitely-playable-test-my-finish
   ?retrieval>
      buffer      failure
   =visual>
      isa         knowledge-obj
      owner       model
      index       =i
   =goal>
      isa         goal-type
      state       play-definitely-playable-test-my
==>
   =goal>
      state       play
   +imaginal>
      isa         imaginal-type
      key         =i
   =visual>
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
   !bind! =s (+ =r 1)
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
   !bind! =s (+ =r 1)
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
   !bind! =s (+ =r 1)
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
   !bind! =s (+ =r 1)
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
   !bind! =s (+ =r 1)
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

(P p-play-just-hinted-init-right
   =goal>
      isa         goal-type
      state       play-just-hinted-init-right
==>
   =goal>
      state       attend
      misc1       play-just-hinted-test-my
      misc2       play-just-hinted-failure
      misc3       play-just-hinted-init-right
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

(P p-play-just-hinted-init-left
   =goal>
      isa         goal-type
      state       play-just-hinted-init-left
==>
   =goal>
      state       attend
      misc1       play-just-hinted-test-my
      misc2       play-just-hinted-failure
      misc3       play-just-hinted-init-left
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
      screen-y    lowest
    > screen-y    current
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

(P p-play-just-hinted-check-red-bad-rank
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      red         t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
    - red         =s
   =imaginal>
      isa         imaginal-type
      red         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      red         nil
   =visual>
)

(P p-play-just-hinted-check-red-impossible
   =visual>
      isa         knowledge-obj
      owner       model
    - red         t
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
   =imaginal>
      isa         imaginal-type
      red         t
==>
   =goal>
      state       play-just-hinted-test-my
   =imaginal>
      red         nil
   =visual>
)

(P p-play-just-hinted-check-white-success
   =visual>
      isa         knowledge-obj
      owner       model
      rank        =r
    - rank        nil
      index       =i
      white       t
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       play-just-hinted-test-my
      white       =s
   =imaginal>
      isa         imaginal-type
      white       t
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



; discard-useless
(P p-discard-useless-init-left
   =goal>
      isa         goal-type
      state       discard-useless-init-left
==>
   =goal>
      state       attend
      misc1       discard-useless-test-my
      misc2       discard-useless-failure
      misc3       discard-useless-init-left
   +imaginal>
      yellow      5
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    lowest
    > screen-y    current
   +retrieval>
      isa         color-iter
      next        green
)

(P p-discard-useless-init-right
   =goal>
      isa         goal-type
      state       discard-useless-init-right
==>
   =goal>
      state       attend
      misc1       discard-useless-test-my
      misc2       discard-useless-failure
      misc3       discard-useless-init-right
   +imaginal>
      yellow      5
   +visual-location>
      isa         knowledge-loc
      kind        knowledge-obj
      owner       model
      screen-y    highest
    < screen-y    current
   +retrieval>
      isa         color-iter
      next        green
)

(P p-discard-useless-failure
   =goal>
      isa         goal-type
      state       discard-useless-failure
==>
   =goal>
      state       start
      s4          nil
   -visual-location>
   -imaginal>
)

(P p-discard-useless-test-my-check-color-possible
   =retrieval>
      isa         color-iter
      next        =nc
   =imaginal>
      yellow      =img
   =goal>
      isa         goal-type
      state       discard-useless-test-my
      =nc         =rnc
   =visual>
      isa         knowledge-loc
      owner       model
      =nc         t
   !bind! =m (min =img =rnc)
==>
   =goal>
      state       discard-useless-test-my
   =visual>
   =imaginal>
      yellow      =m
   +retrieval>
      isa         color-iter
      prev        =nc
)

(P p-discard-useless-test-my-check-color-impossible
   =retrieval>
      isa         color-iter
      next        =nc
   =goal>
      isa         goal-type
      state       discard-useless-test-my
   =visual>
      isa         knowledge-loc
      owner       model
    - =nc         t
==>
   =goal>
      state       discard-useless-test-my
   =visual>
   +retrieval>
      isa         color-iter
      prev        =nc
)

(P p-discard-useless-test-my-check-rank-start
   ?retrieval>
      buffer      failure
   =imaginal>
      yellow      =min
   =goal>
      isa         goal-type
      state       discard-useless-test-my
   =visual>
      isa         knowledge-loc
      owner       model
==>
   =goal>
      state       discard-useless-test-my-rank
   +retrieval>
      isa         rank-iter
      rindex      =min
   =visual>
)

(P p-discard-useless-test-my-check-rank-success
   =retrieval>
      next        =nr
   =goal>
      isa         goal-type
      state       discard-useless-test-my-rank
   =visual>
      isa         knowledge-loc
      owner       model
      =nr         nil
==>
   =goal>
      state       discard-useless-test-my-rank
   +retrieval>
      isa         rank-iter
      prev        =nr
   =visual>
)

(P p-discard-useless-test-my-check-rank-failure
   =retrieval>
      next        =nr
   =goal>
      isa         goal-type
      state       discard-useless-test-my-rank
      misc3       =fallback
   =visual>
      isa         knowledge-loc
      owner       model
      =nr         t
==>
   =goal>
      state       =fallback
   -retrieval>
)

(P p-discard-useless-test-my-check-rank-finish
   =retrieval>
      next        nil
   =goal>
      isa         goal-type
      state       discard-useless-test-my-rank
   =visual>
      isa         knowledge-loc
      owner       model
      index       =i
==>
   =goal>
      state       discard
   +imaginal>
      isa         imaginal-type
      key         =i
   =visual>
)



; discard-unhinted
(P p-discard-unhinted-success
   =goal>
      isa         goal-type
      state       discard-unhinted-success
   =visual>
      isa         knowledge-loc
      owner       model
      index       =i
==>
   =goal>
      state       discard
   +imaginal>
      isa         imaginal-type
      key         =i
)

(P p-discard-unhinted-not-found
   =goal>
      isa         goal-type
      state       discard-unhinted-not-found
==>
   =goal>
      state       start
      s5          nil
)



; discard-random
(P p-discard-random-second-step
   =goal>
      isa         goal-type
      state       discard-random
   =visual>
      isa         knowledge-loc
      owner       model
      index       =i
==>
   =goal>
      state       discard
   +imaginal>
      isa         imaginal-type
      key         =i
)



; hint-random
(P p-hint-random-color
   =goal>
      isa         goal-type
      state       hint-random
   =visual>
      isa         card-loc
      owner       partner
      color       =c
==>
   =goal>
      state       hint-color-second
   +retrieval>
      isa         color-iter
      next        =c
)

(P p-hint-random-color-second-step
   =goal>
      isa         goal-type
      state       hint-color-second
   =retrieval>
      isa         color-iter
      cindex       =i
==>
   =goal>
      state       hint-color
   +imaginal>
      isa         imaginal-type
      key         =i
)

(P p-hint-random-rank
   =goal>
      isa         goal-type
      state       hint-random
   =visual>
      isa         card-loc
      owner       partner
      rank        =r
==>
   =goal>
      state       hint-rank
   +imaginal>
      isa         imaginal-type
      key         =r
)



; hint-to-play
(P p-hint-to-play-init-right
   =goal>
      isa         goal-type
      state       hint-to-play-init-right
==>
   =goal>
      state       attend
      misc1       hint-to-play-test-partner
      misc2       hint-to-play-failure
      misc3       hint-to-play-init-right
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
      screen-y    highest
    < screen-y    current
)

(P p-hint-to-play-init-left
   =goal>
      isa         goal-type
      state       hint-to-play-init-left
==>
   =goal>
      state       attend
      misc1       hint-to-play-test-partner
      misc2       hint-to-play-failure
      misc3       hint-to-play-init-left
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
      screen-y    lowest
    > screen-y    current
)

(P p-hint-to-play-failure
   =goal>
      isa         goal-type
      state       hint-to-play-failure
==>
   =goal>
      state       start
      s6          nil
   -visual-location>
)

(P p-hint-to-play-test-partner-success
   =visual>
      isa         card-obj
      owner       partner
      color       =c
      rank        =r
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       hint-to-play-test-partner
      =c          =s
==>
   =goal>
      state       hint-to-play
   =visual>
   +imaginal>
      isa         imaginal-type
      blue        t
      one         t
)

(P p-hint-to-play-test-partner-no-unambiguous-hint
   =goal>
      isa         goal-type
      state       hint-to-play
      misc3       =fallback
      misc4       =p
   =imaginal>
      isa         imaginal-type
      blue        nil
      one         nil
==>
   =goal>
      state       =fallback
   +visual>
      cmd         move-attention
      screen-pos  =p
   -imaginal>
)

(P p-hint-to-play-test-partner-failure
   =visual>
      isa         card-obj
      owner       partner
      color       =c
      rank        =r
   !bind! =s (- =r 1)
   =goal>
      isa         goal-type
      state       hint-to-play-test-partner
      misc3       =fallback
    - =c          =s
==>
   =goal>
      state       =fallback
)

(P p-hint-to-play-test-partner-color
   =visual>
      isa         card-obj
      owner       partner
      color       =c
      screen-pos  =p
   =goal>
      isa         goal-type
      state       hint-to-play
      misc3       =fallback
   =imaginal>
      isa         imaginal-type
      blue        t
==>
   =goal>
      state       attend
      misc1       hint-to-play-test-color-found
      misc2       hint-to-play-test-color-not-found
      misc3       =fallback
      misc4       =p
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
    > screen-y    current
      color       =c
   +retrieval>
      isa         color-iter
      next        =c
   =imaginal>
)

(P p-hint-to-play-test-partner-color-success
   =goal>
      isa         goal-type
      state       hint-to-play-test-color-not-found
   =retrieval>
      isa         color-iter
      cindex      =i
==>
   =goal>
      state       hint-color
   +imaginal>
      isa         imaginal-type
      key         =i
)

(P p-hint-to-play-test-partner-color-failure
   =goal>
      isa         goal-type
      state       hint-to-play-test-color-found
      misc4       =p
   =retrieval>
      isa         color-iter
      cindex      =i
   =imaginal>
==>
   =goal>
      state       hint-to-play
   =imaginal>
      blue        nil
   +visual>
      cmd         move-attention
      screen-pos  =p
)

(P p-hint-to-play-test-partner-rank
   =visual>
      isa         card-obj
      owner       partner
      rank        =r
      screen-pos  =p
   =goal>
      isa         goal-type
      state       hint-to-play
   =imaginal>
      isa         imaginal-type
      one         t
==>
   =goal>
      state       attend
      misc1       hint-to-play-test-rank-found
      misc2       hint-to-play-test-rank-not-found
      misc4       =p
   +visual-location>
      isa         card-loc
      kind        card-obj
      owner       partner
    > screen-y    current
      rank        =r
   =imaginal>
      isa         imaginal-type
      key         =r
)

(P p-hint-to-play-test-partner-rank-success
   =goal>
      isa         goal-type
      state       hint-to-play-test-rank-not-found
==>
   =goal>
      state       hint-rank
)

(P p-hint-to-play-test-partner-rank-failure
   =goal>
      isa         goal-type
      state       hint-to-play-test-rank-found
      misc4       =p
   =imaginal>
==>
   =goal>
      state       hint-to-play
   =imaginal>
      one         nil
   +visual>
      cmd         move-attention
      screen-pos  =p
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
      isa         imaginal-type
      key         =key
==>
   =goal>
      state       done
   +manual>
      cmd         press-key
      key         =key
)

(goal-focus goal)

(spp s-hint-random :u -20 :reward t)

(spp p-play-definitely-playable-failure :reward t)
(spp p-play-potentially-playable-failure :reward t)
(spp p-play-just-hinted-not-found :reward t)
(spp p-discard-useless-failure :reward t)
(spp p-discard-unhinted-not-found :reward t)
(spp p-hint-to-play-failure :reward t)

(spp inform-discard-neutral :reward t)
(spp inform-play-successful :reward 40)
(spp inform-play-unsuccessful :reward -10)
(spp inform-discard-useless :reward 30)
(spp inform-discard-playable :reward -10)
)
