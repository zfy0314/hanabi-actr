import actr
from player import ActionType as AT
from player import Action, Player
from utils import Color, Rank


class ActrPlayer(Player):
    def __init__(self, name, pnr, model_path="ACT-R:final;model.lisp"):
        self.name = name
        self.pnr = pnr
        self.ppnr = 1 - self.pnr

        actr.load_act_r_model(model_path)
        actr.install_device(actr.open_exp_window("Hanabi", visible=False))
        self.response = ""

        self.ATmap = [None, "C", "R", "P", "D"]
        self.ranks = ["zero", "one", "two", "three", "four", "five"]
        self.nrmap = [None, self.ppnr, self.ppnr, pnr, pnr]

    def _card_info(self, name, x, y, color, rank, owner, index=None, count=None):
        return [
            "isa",
            [name + "-loc", name + "-obj"],
            "screen-x",
            x,
            "screen-y",
            y,
            "color",
            color,
            "rank",
            rank,
            "owner",
            owner,
            "index",
            index,
            "count",
            count,
        ]

    def _show_state(self, game):
        actr.clear_exp_window()
        visicons = []

        # board
        for i, color in enumerate(Color):
            visicons.append(
                self._card_info(
                    "card",
                    0,
                    i * 10,
                    color.name,
                    self.ranks[game.board[color]],
                    "board",
                )
            )

        # partner's hand and their knowledge
        for i, card in enumerate(game.hands[self.ppnr].cards):
            visicons.append(
                self._card_info(
                    "card",
                    20,
                    i * 10,
                    card.get_color(self.pnr).name,
                    self.ranks[card.get_rank(self.pnr)],
                    "partner",
                    index=i + 1,
                )
            )
            pcolors = card.get_color(self.ppnr)
            pranks = card.get_rank(self.ppnr)
            kcolors = sum([[color.name, color in pcolors] for color in Color], [])
            kranks = sum([[rank.name, rank in pranks] for rank in Rank], [])
            visicons.append(
                self._card_info(
                    "knowledge",
                    40,
                    i * 10,
                    None if len(pcolors) > 1 else list(pcolors)[0].name,
                    None if len(pranks) > 1 else list(pranks)[0].name,
                    "partner",
                    index=i + 1,
                )
                + kcolors
                + kranks
            )

        # own knowledge
        for i, card in enumerate(game.hands[self.pnr].cards):
            pcolors = card.get_color(self.pnr)
            pranks = card.get_rank(self.pnr)
            kcolors = sum([[color.name, color in pcolors] for color in Color], [])
            kranks = sum([[rank.name, rank in pranks] for rank in Rank], [])
            visicons.append(
                self._card_info(
                    "knowledge",
                    60,
                    i * 10,
                    None if len(pcolors) > 1 else list(pcolors)[0].name,
                    None if len(pranks) > 1 else list(pranks)[0].name,
                    "model",
                    index=i + 1,
                )
                + kcolors
                + kranks
                + ["hinted", i + 1 in game.hands[self.pnr].last_hinted]
            )

        # trash
        for i, (c, r, count) in enumerate(game.trash.all):
            visicons.append(
                self._card_info("card", 80, i * 10, c, r, "trash", count=count)
            )

        actr.add_visicon_features(*visicons)

    def _get_key(self, model, key):
        self.response += key

    def _set_goal(self, state, game):
        goal = ["state", state, "hints", game.hints, "hits", game.hits]
        if actr.buffer_read("goal"):
            actr.mod_focus(*goal)
        else:
            actr.goal_focus(actr.define_chunks(["isa", "goal-type"] + goal)[0])

    def get_action(self, game):

        # re-encode game state
        self._show_state(game)

        # get response from model for choosing an action
        actr.add_command(
            "key-press",
            self._get_key,
            "key press monitor",
        )
        actr.monitor_command("output-key", "key-press")
        self._set_goal("start", game)
        actr.run(100)
        actr.remove_command_monitor("output-key", "key-press")
        actr.remove_command("key-press")

        # return action
        index = self.ATmap.index(self.response[0].upper())
        action = Action(AT(index), eval(self.response[1]), self.nrmap[index])
        self.response = ""
        return action

    def inform(self, pnr, action, game):
        pass


if __name__ == "__main__":
    from game import Game
    from human import HumanPlayer

    G = Game(
        [ActrPlayer("Alice", 0), HumanPlayer("bob", 1, debug=True)], seed="noshuffle"
    )
    score = G.run()
    print("score: ", score)
