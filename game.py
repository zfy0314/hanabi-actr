from player import ActionType
import utils


class Game:
    def __init__(self, players):
        self.debug = True
        self.players = players
        self.reset()

    def reset(self):
        self.board = utils.Board()
        self.trash = utils.Trash()
        self.deck = utils.Deck()
        self.hands = [utils.Hand(self.deck, player.name) for player in self.players]
        self.hints = 8
        self.hits = 0
        self.extra = 0  # extra turn after deck is empty
        self.current_player = -1

    def _print(self, *args):
        if self.debug:
            print(*args)

    def turn(self):
        """A single turn for a single player"""
        self.current_player = (self.current_player + 1) % len(self.players)
        action = self.players[self.current_player].get_action(self)

        if action.type in [ActionType.hint_color, ActionType.hint_rank]:
            if self.hints == 0:
                self._print("bad attempt to hint when no hint token is available")
                return False
            elif action.pnr == self.current_player:
                self._print("bad attempt to hint one's self")
                return False
            else:
                self.hints -= 1
                getattr(self.hands[action.pnr], action.type.name)(action.index)
        elif action.type == ActionType.play:
            card = self.hands[self.current_player].remove(action.index)
            if card is None:
                self._print("bad attempt to play non existing card")
                return False
            if not self.board.play(card):
                self.trash.add(card)
                self.hits += 1
                if self.hits == 3:
                    self._print("3 strikes!")
                    return False
            else:
                self.hints = min(8, self.hints + (card._rank == 5))
        elif action.type == ActionType.discard:
            card = self.hands[self.current_player].remove(action.index)
            if card is None:
                self._print("bad attempt to discard non existing card")
                return False
            if self.hints == 8:
                self._print("bad attempt to discard with all hint tokens")
                return False
            self.trash.add(card)
            self.hints += 1

        for player in self.players:
            player.inform(action, self)

        self.extra += self.deck.isempty
        return self.extra < 2

    def run(self):
        while self.turn():
            pass
        return self.board.score
