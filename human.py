from player import ActionType, Action, Player
from utils import Color


class HumanPlayer(Player):
    """A bare minimum of 2-player interative interface; mainly for debugging use"""

    def __init__(self, name, pnr):
        self.name = name
        self.pnr = pnr

    def get_action(self, game):
        print("=" * 32)
        print(self.pnr, self.name)
        print("=" * 32)
        print("#hint: ", game.hints)
        print("#hit: ", game.hits)
        print("-" * 32)
        print("Partner: ")
        print(game.hands[1 - self.pnr])
        print("Partner Knowledge: ")
        game.hands[1 - self.pnr].show_knowledge()
        print("-" * 32)
        print(game.board)
        print("-" * 32)
        print("Self Knowledge: ")
        game.hands[self.pnr].show_knowledge()
        print("-" * 32)
        print(game.trash)
        print("-" * 32)
        print({color.name: color.value for color in sorted(Color)})

        mapping = {
            "HC": ActionType.hint_color,
            "HR": ActionType.hint_rank,
            "PL": ActionType.play,
            "DC": ActionType.discard,
        }
        action = input(str(mapping) + "\nnext action: ")
        while True:
            try:
                action_type, action_index = action.split(" ")
                action = Action(mapping[action_type], eval(action_index), 1 - self.pnr)
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

    def inform(self, action, game):
        print("partner plays:", action)


if __name__ == "__main__":
    from game import Game

    G = Game([HumanPlayer("Alice", 0), HumanPlayer("Bob", 1)])
    score = G.run()
    print("score: ", score)
