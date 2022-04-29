import argparse
import importlib
from random import seed

from baseline import HardcodedPlayer
from game import Game
from human import HumanPlayer
from model import ActrPlayer
from utils import DataObject


agent_map = {
    "ACTR": ActrPlayer,
    "baseline": HardcodedPlayer,
    "human": HumanPlayer,
}


def experiment(player1, player2, **kwargs):

    assert (
        player1 != "ACTR" or player2 != "ACTR"
    ), "two ACT-R agents game is not currently supported"
    players = [
        agent_map.get(player1, HardcodedPlayer)("Alice", 0, kwargs.get("debug", False)),
        agent_map.get(player2, HardcodedPlayer)("Bob", 1, kwargs.get("debug", False)),
    ]

    if kwargs.get("runs", 1) == 1 and kwargs.get("games", 1) == 1:
        G = Game(players, seed=kwargs.get("seed", 0))
        G.run()
        print(G.summary)
    else:
        seed(kwargs.get("seed", 0))
        G = Game(players)
        all_data = DataObject(
            kwargs.get("title", " [{}] vs. [{}] ".format(player1, player2))
        )
        try:
            wrapper = importlib.import_module("tqdm").tqdm
        except ModuleNotFoundError:
            wrapper = lambda x: x  # noqa

        for j in range(kwargs.get("runs", 1)):
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
        if "interact" in kwargs.keys():
            import pdb

            pdb.set_trace()


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
    args = parser.parse_args()
    experiment(**args.__dict__)
