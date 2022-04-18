from player import ActionType as AT
from player import Action, Player
from utils import Color


class HumanPlayer(Player):
    """A bare minimum of 2-player interative interface; mainly for debugging use"""

    def __init__(self, name, pnr, debug=False):
        self.name = name
        self.pnr = pnr
        self.debug = debug

    def get_action(self, game):
        print("\n\n")
        print("=" * 32)
        print(self.pnr, self.name)
        print("=" * 32)
        print("#hint: ", game.hints)
        print("#hit: ", game.hits)
        print("-" * 32)
        print("Partner: ")
        print(game.hands[1 - self.pnr])
        print("-" * 32)
        print("Partner Knowledge: ")
        game.hands[1 - self.pnr].show_knowledge()
        print("-" * 32)
        print(game.board)
        if self.debug:
            print("-" * 32)
            print("Hand: ")
            print(game.hands[self.pnr])
        print("-" * 32)
        print("Self Knowledge: ")
        game.hands[self.pnr].show_knowledge()
        print("-" * 32)
        print(game.trash)
        print("-" * 32)
        print({color.name: color.value for color in sorted(Color)})

        mapping = {
            "HC": AT.hint_color,
            "HR": AT.hint_rank,
            "PL": AT.play,
            "DC": AT.discard,
        }
        action = input(str(mapping) + "\nnext action: ")
        while True:
            try:
                action_type, action_index = action.split(" ")
                action_type = action_type.upper()
                action_index = eval(action_index)
                action = Action(mapping[action_type], action_index, 1 - self.pnr)
                assert 1 <= action_index and action_index <= 5
                assert game.hints > 0 or action_type not in ["HC", "HR"]
                assert game.hints < 8 or action_type != "DC"
                break
            except (KeyError, AssertionError, ValueError) as e:
                action = input("invalid action ({}), try another: ".format(type(e)))
        print("got", action)
        print("=" * 32)
        print("\n\n")
        return action

    def inform(self, pnr, action, game):
        print(pnr, "played", action)

    def reset(self):
        pass


if __name__ == "__main__":
    from game import Game

    G = Game([HumanPlayer("Alice", 0), HumanPlayer("Bob", 1)])
    score = G.run()
    print("score: ", score)
