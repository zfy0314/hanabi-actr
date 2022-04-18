import actr
from player import ActionType as AT
from player import Action, Player
from utils import Color, Rank


class ActrPlayer(Player):
    def __init__(self, name, pnr, debug=False, model_path="ACT-R:final;model.lisp"):
        self.name = name
        self.pnr = pnr
        self.ppnr = 1 - self.pnr

        actr.load_act_r_model(model_path)
        actr.install_device(actr.open_exp_window("Hanabi", visible=False))
        actr.set_parameter_value(":v", debug)
        self.response = ""

        self.ATmap = [None, "C", "R", "P", "D"]
        self.ranks = ["zero", "one", "two", "three", "four", "five"]
        self.nrmap = [None, self.ppnr, self.ppnr, pnr, pnr]
        self.reset()

    def reset(self):
        self.last_hinted = set()

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
        actr.delete_all_visicon_features()
        visicons = []

        # board
        # for i, color in enumerate(Color):
        #     visicons.append(
        #         self._card_info(
        #             "card",
        #             0,
        #             i * 10,
        #             color.name,
        #             self.ranks[game.board[color]],
        #             "board",
        #         )
        #     )

        # partner's hand and their knowledge
        for i, card in enumerate(game.hands[self.ppnr].cards):
            visicons.append(
                self._card_info(
                    "card",
                    20,
                    i * 10,
                    card.get_color(self.pnr).name,
                    card.get_rank(self.pnr).value,
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
                    None if len(pranks) > 1 else list(pranks)[0].value,
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
                    None if len(pranks) > 1 else list(pranks)[0].value,
                    "model",
                    index=i + 1,
                )
                + kcolors
                + kranks
                + ["hinted", i + 1 in self.last_hinted]
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
        goal += sum([[color.name, game.board[color]] for color in Color], [])
        goal += sum([["s" + str(i), True] for i in range(1, 8)], [])
        goal += ["misc1", None, "misc2", None]
        if actr.buffer_read("goal"):
            actr.mod_focus(*goal)
        else:
            actr.goal_focus(actr.define_chunks(["isa", "goal-type"] + goal)[0])

    def _log_state(self, game):
        self.state_hits = game.hits

    def get_action(self, game):

        # re-encode game state
        self._log_state(game)
        self._show_state(game)

        # get response from model for choosing an action
        actr.add_command(
            "key-press",
            self._get_key,
            "key press monitor",
        )
        actr.monitor_command("output-key", "key-press")
        self._set_goal("start", game)
        actr.run(200)
        actr.remove_command_monitor("output-key", "key-press")
        actr.remove_command("key-press")

        # return action
        index = self.ATmap.index(self.response[0].upper())
        action = Action(AT(index), eval(self.response[1]), self.nrmap[index])
        self.response = ""
        return action

    def inform(self, pnr, action, game):
        if pnr == self.pnr:
            self.last_hinted = set()
        if action.type in [AT.hint_color, AT.hint_rank] and action.pnr == self.pnr:
            self.last_hinted = game.hands[self.pnr].last_hinted
        update = False
        if action.type == AT.play:
            if self.state_hits < game.hits:
                self._set_goal("play-unsuccessful", game)
            else:
                self._set_goal("play-successful", game)
        elif action.type == AT.discard:
            card = game.trash.most_recent
            card.game = game
            if game.board.playable(card):
                self._set_goal("discard-playable", game)
            elif card.useless:
                self._set_goal("discard-useless", game)
            else:
                self._set_goal("discard-neutral", game)
        if update:
            actr.run(10)
            self._log_state(game)


if __name__ == "__main__":
    from game import Game
    import utils
    import argparse
    from random import seed

    parser = argparse.ArgumentParser(description="ACT-R agent for Hanabi")
    parser.add_argument(
        "--human", action="store_true", help="play the ACT-R with a cli interface"
    )
    parser.add_argument(
        "--switch", action="store_true", help="change the order of the players"
    )
    parser.add_argument("--debug", action="store_true", help="enable debugging message")
    parser.add_argument(
        "--seed", default=0, help="seed for initializing the deck", type=int
    )
    parser.add_argument("--runs", default=1, help="number of games", type=int)
    parser.add_argument("--plot", action="store_true", help="plot scores")
    parser.add_argument(
        "--png",
        default="performance_curve.png",
        help="file name for score plot",
        type=str,
    )
    args = parser.parse_args()
    utils.debugging = args.debug

    if args.human:
        from human import HumanPlayer

        if args.switch:
            players = [
                ActrPlayer("Alice", 0, debug=args.debug),
                HumanPlayer("Bob", 1, debug=args.debug),
            ]
        else:
            players = [
                HumanPlayer("Alice", 0, debug=args.debug),
                ActrPlayer("Bob", 1, debug=args.debug),
            ]
    else:
        from baseline import HardcodedPlayer

        if args.switch:
            players = [
                ActrPlayer("Alice", 0, debug=args.debug),
                HardcodedPlayer("Bob", 1),
            ]
        else:
            players = [
                HardcodedPlayer("Alice", 0),
                ActrPlayer("Bob", 1, debug=args.debug),
            ]

    if args.runs == 1:
        G = Game(players, seed=args.seed)
        score = G.run()
        print(
            "score: ",
            score,
            " hints: ",
            G.hints,
            " hits: ",
            G.hits,
            " turns: ",
            G.turns,
        )
    else:
        seed(args.seed)
        scores = []
        G = Game(players)
        try:
            from tqdm import tqdm

            bar = tqdm(list(range(args.runs)))
        except ModuleNotFoundError:
            bar = range(args.runs)
        for i in bar:
            scores.append(G.run())
            G.reset(None)
        print(
            "{} games:\n  avg: {}, min: {}, max: {}, mode: {}".format(
                args.runs,
                sum(scores) / args.runs,
                min(scores),
                max(scores),
                max(set(scores), key=scores.count),
            )
        )

        if args.plot:
            from matplotlib import pyplot as plt

            plt.plot(range(len(scores)), scores)
            plt.xlabel("games")
            plt.ylabel("score")
            plt.title("score of ACT-R agent over {} games".format(args.runs))
            plt.savefig(args.png)
