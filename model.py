import actr
from player import ActionType as AT
from player import Action, Player
from utils import Color, Rank


class ActrPlayer(Player):
    def __init__(
        self,
        name,
        pnr,
        debug=False,
        model_path="ACT-R:hanabi-actr;model.lisp",
        log_utility=False,
        utility_learning=True,
    ):
        self.name = name
        self.pnr = pnr
        self.ppnr = 1 - self.pnr
        self.debug = debug
        if not self.debug:
            actr.stop_output()
        self.log_utility = log_utility
        if log_utility:
            self.utilities = {}
            self.utility_boundary = []
        self.model_path = model_path
        self.utility_learning = utility_learning

        self.ATmap = [None, "C", "R", "P", "D"]
        self.ranks = ["zero", "one", "two", "three", "four", "five"]
        self.nrmap = [None, self.ppnr, self.ppnr, pnr, pnr]
        self.reload()

    def reset(self):
        self.last_hinted = set()
        self.response = ""
        if self.log_utility:
            self.utility_boundary.append(
                max([len(x) for x in self.utilities.values()] + [0])
            )

    def reload(self):
        actr.reset()
        actr.load_act_r_model(self.model_path)
        actr.install_device(actr.open_exp_window("Hanabi", visible=False))
        actr.set_parameter_value(":v", self.debug)
        actr.set_parameter_value(":cmdt", self.debug)
        actr.set_parameter_value(":model-warnings", self.debug)
        actr.set_parameter_value(":ul", self.utility_learning)
        if self.log_utility:
            self.utilities = {}
            self.utility_boundary = []

    def _log_strategy_utility(self):
        if self.log_utility:
            for p in actr.all_productions():
                if p.startswith("S-"):
                    if p in self.utilities.keys():
                        self.utilities[p].append(actr.spp(p, ":u")[0][0])
                    else:
                        self.utilities[p] = [actr.spp(p, ":u")[0][0]]

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
        self._log_strategy_utility()
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

    def plot_utilities(self, png_file):
        import matplotlib.pyplot as plt

        plt.figure(figsize=(10, 7), dpi=80)
        for p, utils in self.utilities.items():
            plt.plot(range(len(utils)), utils, label=p)
        xmin, xmax, ymin, ymax = plt.axis()
        plt.vlines(
            x=self.utility_boundary,
            ymin=ymin,
            ymax=ymax,
            ls="--",
            label="game boundaries",
            color="black",
        )
        plt.xlabel("numbers of action taken")
        plt.ylabel("utility")
        plt.legend(bbox_to_anchor=(0, -0.1), loc="upper left")
        plt.tight_layout()
        plt.savefig(png_file)
        plt.close()


if __name__ == "__main__":
    from experiment import experiment

    experiment(
        "baseline",
        "ACTR",
        runs=200,
        games=10,
        plot_curve="curve_variants.png",
        plot_diff="diff_variants.png",
        save_pkl="data_variants.pkl",
    )
