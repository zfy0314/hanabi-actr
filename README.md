# Hanabi-ACTR
Final Project for CMU 85-412 Cognitive Modeling

## Files
```sh
.
├── actr.py                  # interface for interacting with actr
├── baseline.py              # baseline agent
├── experiment.py            # wrapper for running experiments
├── game.py                  # game environment of Hanabi
├── human.py                 # command line interface for human to play
├── model.lisp               # ACTR model
├── model_preference.lisp    # ACTR model with only the subset strategy in the baseline player
├── model.py                 # interface for ACTR model to iteract with the game environment
├── player.py                # basic class of player and action
└── utils.py                 # basic class and some helper functions
```

## Getting Started
1. Install ACT-R from http://act-r.psy.cmu.edu/software/
2. Clone this project into the root directory of `ACT-R`
3. To reproduce the figures in the report, use `python3 experiment.py --report`
4. Check `python3 experiment.py -h` for details on running other experiments

## Human Interface
There is a minimal commandline interface to interaction with the agent in the game environment. It will be something like the following:
```sh
================================
0 Alice
================================
#hint:  5
#hit:  0
--------------------------------
Partner: 
['<red 3>', '<green 5>', '<white 1>', '<white 4>', '<yellow 2>']
--------------------------------
Partner Knowledge: 
 1             red                2 3 4 5
 2  blue green           yellow   2 3 4 5
 3                 white        1        
 4  blue green red white yellow 1 2 3 4 5
 5  blue green red white yellow 1 2 3 4 5
--------------------------------
Board:
blue: 1 | green: 0 | red: 1 | white: 1 | yellow: 0 |
--------------------------------
Hand: 
['<red 2>', '<yellow 4>', '<red 3>', '<green 3>', '<green 2>']
--------------------------------
Self Knowledge: 
 1       green red white yellow 1 2 3 4 5
 2       green red white yellow 1 2 3 4 5
 3       green red white yellow 1 2 3 4 5
 4       green red white yellow 1 2 3 4 5
 5  blue green red white yellow 1 2 3 4 5
--------------------------------
Trash:
  blue:   
  green:  
  red:    
  white:  1 
  yellow: 

--------------------------------
{'blue': 1, 'green': 2, 'red': 3, 'white': 4, 'yellow': 5}
{'HC': <ActionType.hint_color: 1>, 'HR': <ActionType.hint_rank: 2>, 'PL': <ActionType.play: 3>, 'DC': <ActionType.discard: 4>}
next action: 
```

* On the banner there are player ID and name, by default the first player will have ID 0 and the second will have ID 1.
* Below the banner is the basic information of the game (how many hint tokens left and how many mistakes has been made).
* Then there is the hand of the partner, you will have full knowledge of their cards
* The **Partner Knowledge** section represents what the partner knowns about their cards. It aggregates all past hits. The colors and ranks shown are those that are possible.
* The **Board** section keep track of all the successful plays in each color
* The **Hand** section will only be shown in *debug* model. It is the same as what the partner will have access to.
* **Self Knowledge** follows the same convention as **Partner Knowledge**
* The **Trash** section shows all the discarded cards and unsuccessful plays, ordered in ranks and grouped by colors.
* Do perform a move, use the combination `<ACTION> <INDEX>`, as displayed, `PL` corresponds to `PLAY`, `DC` corresponds to `DISCARD`, `HC` corresponds to `HINT COLOR`, `HR` corresponds to `HINT RANK`. Each color corresponds to a code listed above. So if you want to hint your partner white cards, you should type `HC 4`. If you want to discard the fifth card, type `DC 5`. Note that the cards are 1-indexed from the left to right.
