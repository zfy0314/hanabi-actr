from player import ActionType as AT
import utils


class Game:
    def __init__(self, players, seed=None):
        self.debug = True
        self.players = players
        self.reset(seed)

    def reset(self, seed):
        self.board = utils.Board()
        self.trash = utils.Trash()
        self.deck = utils.Deck(game=self, init=seed)
        self.hands = [utils.Hand(self.deck, player.pnr) for player in self.players]
        self.hints = 8
        self.hits = 0
        self.extra = 0  # extra turns after deck is empty
        self.turns = 0
        self.current_player = -1
        self.action_log = []
        for player in self.players:
            player.reset()

    def turn(self):
        """A single turn for a single player"""
        self.turns += 1
        self.current_player = (self.current_player + 1) % len(self.players)
        action = self.players[self.current_player].get_action(self)
        self.action_log.append(action)

        if action.type in [AT.hint_color, AT.hint_rank]:
            if self.hints == 0:
                utils._print("bad attempt to hint when no hint token is available")
                return False
            elif action.pnr == self.current_player:
                utils._print("bad attempt to hint one's self")
                return False
            else:
                self.hints -= 1
                getattr(self.hands[action.pnr], action.type.name)(action.index)
        elif action.type == AT.play:
            card = self.hands[self.current_player].remove(action.index)
            if card is None:
                utils._print("bad attempt to play non existing card")
                return False
            if not self.board.play(card):
                self.trash.add(card)
                self.hits += 1
                if self.hits == 3:
                    utils._print("3 strikes!")
                    return False
            else:
                self.hints = min(8, self.hints + (card._rank == 5))
        elif action.type == AT.discard:
            card = self.hands[self.current_player].remove(action.index)
            if card is None:
                utils._print("bad attempt to discard non existing card")
                return False
            if self.hints == 8:
                utils._print("bad attempt to discard with all hint tokens")
                return False
            self.trash.add(card)
            self.hints += 1

        for player in self.players:
            player.inform(self.current_player, action, self)

        self.extra += self.deck.isempty
        return self.extra < 2

    def run(self):
        while self.turn():
            pass
        return self.board.score
