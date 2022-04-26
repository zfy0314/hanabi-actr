import pickle

import actr
from player import ActionType as AT
from player import Action, Player
from utils import Color, Rank


class ActrPlayer(Player):
    def __init__(
        self, name, pnr, debug=False, model_path="ACT-R:hanabi-actr;model.lisp"
    ):
        self.name = name
        self.pnr = pnr
        self.ppnr = 1 - self.pnr
        self.debug = debug
        self.model_path = model_path

        self.ATmap = [None, "C", "R", "P", "D"]
        self.ranks = ["zero", "one", "two", "three", "four", "five"]
        self.nrmap = [None, self.ppnr, self.ppnr, pnr, pnr]
        self.reload()

    def reset(self):
        self.last_hinted = set()
        self.response = ""

    def reload(self):
        actr.reset()
        actr.load_act_r_model(self.model_path)
        actr.install_device(actr.open_exp_window("Hanabi", visible=False))
        actr.set_parameter_value(":v", self.debug)

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
            update = True
            if self.state_hits < game.hits:
                self._set_goal("play-unsuccessful", game)
            else:
                self._set_goal("play-successful", game)
        elif action.type == AT.discard:
            update = True
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
    parser.add_argument("--runs", default=1, help="number of trials", type=int)
    parser.add_argument(
        "--games", default=1, help="number of games in each trial", type=int
    )
    parser.add_argument(
        "--save_data",
        action="store_true",
        help="save the game states into a pickle file",
    )
    parser.add_argument(
        "--pkl_data",
        default="actr_data.pkl",
        help="file name for game data",
        type=str,
    )
    parser.add_argument("--plot", action="store_true", help="plot scores")
    parser.add_argument(
        "--png_plot",
        default="performance_curve.png",
        help="file name for score plot",
        type=str,
    )
    parser.add_argument("--dist", action="store_true", help="draw score distribution")
    parser.add_argument(
        "--png_dist",
        default="actr_distribution.png",
        help="file name for distribution plot",
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

    if args.runs == 1 and args.games == 1:
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
        G = Game(players)
        all_data = []
        try:
            from tqdm import tqdm

            wrapper = tqdm
        except ModuleNotFoundError:
            wrapper = lambda x: x  # noqa
        scores = [[] for _ in range(args.games)]
        for j in range(args.runs):
            G.reload()
            for i in wrapper(list(range(args.games))):
                scores[i].append(G.run())
                all_data.append(
                    {
                        "trial": j,
                        "game": i,
                        "score": G.score,
                        "turns": G.turns,
                        "hints": G.hints,
                        "hits": G.hits,
                    }
                )
                G.reset(None)
        scores = [sorted(s) for s in scores]
        scores_mean = [sum(s) / args.runs for s in scores]
        scores_lower = [s[args.runs // 4] for s in scores]
        scores_upper = [s[3 * args.runs // 4] for s in scores]
        print(
            "{} games:\n  avg: {}, min: {}, max: {}, mode: {}".format(
                args.games,
                sum(scores_mean) / args.games,
                min(scores_mean),
                max(scores_mean),
                max(set(scores_mean), key=scores.count),
            )
        )

        if args.plot:
            from matplotlib import pyplot as plt

            plt.plot(range(1, 1 + args.games), scores_mean)
            plt.fill_between(
                range(1, 1 + args.games), scores_lower, scores_upper, alpha=0.2
            )
            plt.xlabel("games")
            plt.ylabel("score")
            plt.title(
                "score of ACT-R agent over {} games averaged over {} trails".format(
                    args.games, args.runs
                )
            )
            plt.savefig(args.png_plot)

        if args.dist:
            from matplotlib import pyplot as plt

            plt.hist(scores_mean, range(27), density=True)
            plt.xlabel("score")
            plt.ylabel("density")
            plt.title(
                "distribution of actr vs. baseline over {} games".format(args.runs)
            )
            plt.savefig(args.png_dist)

        if args.save_data:
            pickle.dump(all_data, open(args.pkl_data, "wb"))
