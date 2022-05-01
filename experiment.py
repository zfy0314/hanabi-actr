import argparse
import importlib
from random import seed

import actr
from baseline import HardcodedPlayer
from game import Game
from human import HumanPlayer
from player import Player
from model import ActrPlayer
from utils import DataObject


agent_map = {
    "ACTR": ActrPlayer,
    "baseline": HardcodedPlayer,
    "human": HumanPlayer,
}


def experiment(player1, player2, **kwargs):

    if not isinstance(player1, Player):
        player1 = agent_map.get(player1, HardcodedPlayer)(
            "Alice", 0, kwargs.get("debug", False)
        )
    if not isinstance(player2, Player):
        player2 = agent_map.get(player2, HardcodedPlayer)(
            "Bob", 1, kwargs.get("debug", False)
        )
    assert (
        type(player1).__name__ != "ActrPlayer" or type(player2).__name__ != "ActrPlayer"
    ), "two ACT-R agents game is not currently supported"
    players = [player1, player2]

    if kwargs.get("runs", 1) == 1 and kwargs.get("games", 1) == 1:
        G = Game(players, seed=kwargs.get("seed", 0))
        G.run()
        print(G.summary)
    else:
        seed(kwargs.get("seed", 0))
        G = Game(players)
        all_data = DataObject(
            title=kwargs.get(
                "title",
                " [{}] vs. [{}] ".format(
                    type(player1).__name__, type(player2).__name__
                ),
            ),
            data=[],
            trials=set(),
            games=set(),
        )
        try:
            tqdm = importlib.import_module("tqdm")
            wrapper = lambda x: tqdm.tqdm(x, leave=False) if len(x) > 1 else x  # noqa
        except ModuleNotFoundError:
            wrapper = lambda x: x  # noqa

        for j in wrapper(range(kwargs.get("runs", 1))):
            G.reload()
            for i in wrapper(list(range(kwargs.get("games", 1)))):
                G.run()
                all_data.log_game(G, j, i + 1)
                G.reset(None)
        all_data.print_summary()

        if kwargs.get("plot_dist", None) is not None:
            all_data.plot_density(kwargs["plot_dist"])
        if kwargs.get("plot_curve", None) is not None:
            all_data.plot_curve(kwargs["plot_curve"])
        if kwargs.get("plot_diff", None) is not None:
            all_data.plot_difference(kwargs["plot_diff"])
        if kwargs.get("save_pkl", None) is not None:
            all_data.save_to_pkl(kwargs["save_pkl"])
        if kwargs.get("save_txt", None) is not None:
            all_data.save_to_txt(kwargs["save_txt"])

    return players


def report():

    # Distribution of baseline
    experiment("baseline", "baseline", runs=500, games=1, plot_dist="Fig2.png")

    # Preference learning
    player2 = ActrPlayer("Bob", 1, model_path="ACT-R:hanabi-actr;model_preference.lisp")
    experiment(
        "baseline",
        player2,
        runs=200,
        games=10,
        plot_curve="Fig4a.png",
        plot_diff="Fig4b.png",
    )
    experiment("baseline", player2, runs=200, plot_dist="Fig5b.png")
    player2 = ActrPlayer(
        "Bob",
        1,
        model_path="ACT-R:hanabi-actr;model_preference.lisp",
        utility_learning=False,
    )
    experiment("baseline", player2, runs=200, plot_dist="Fig5a.png")
    player2 = ActrPlayer(
        "Bob", 1, model_path="ACT-R:hanabi-actr;model_preference.lisp", log_utility=True
    )
    players = experiment("baseline", player2, games=200)
    players[1].plot_utilities("Fig6.png")

    # Variant learning
    player2 = ActrPlayer("Bob", 1)
    experiment(
        "baseline",
        player2,
        runs=200,
        games=10,
        plot_curve="Fig7a.png",
        plot_diff="Fig8b.png",
    )
    experiment("baseline", player2, runs=200, plot_dist="Fig8b.png")
    player2 = ActrPlayer(
        "Bob",
        1,
        utility_learning=False,
    )
    experiment("baseline", player2, runs=200, plot_dist="Fig8a.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Hanabi Agents Interactive Environment"
    )
    parser.add_argument(
        "--player1", choices=["ACTR", "baseline", "human"], default="baseline", type=str
    )
    parser.add_argument(
        "--player2", choices=["ACTR", "baseline", "human"], default="baseline", type=str
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
        "--plot_dist", help="file name for plotting distribution", type=str
    )
    parser.add_argument(
        "--plot_curve", help="file name for plotting performance curve", type=str
    )
    parser.add_argument(
        "--plot_diff", help="file name for plotting difference", type=str
    )
    parser.add_argument(
        "--save_pkl", help="file name for saving data in pkl format", type=str
    )
    parser.add_argument(
        "--save_txt", help="file name for saving data in txt format", type=str
    )
    parser.add_argument(
        "--report",
        help="generate the figures in the report, if set, ignore all other arguments",
        action="store_true",
    )
    args = parser.parse_args()
    if args.report:
        report()
    else:
        experiment(**args.__dict__)
