"""Python planning/reference version of the MIPS Treasure Hunt game."""

import random


WALL = "#"
EMPTY = "."
TREASURE = "T"
EXIT = "E"
PLAYER = "P"
KILLER = "K"

STARTING_LIVES = 3
TREASURE_POINTS = 100
DEATH_PENALTY = 50
PLAYER_START = (1, 1)
ENEMY_STARTS = ((1, 6), (6, 6))
EXIT_CORNERS = ((1, 1), (1, 6), (6, 1), (6, 6))

# Each new game randomly chooses one of these three connected mazes.
MAZES = (
    (
        "########",
        "#...T..#",
        "#.##.#.#",
        "#......#",
        "#.#.##.#",
        "#T.....#",
        "#..T...#",
        "########",
    ),
    (
        "########",
        "#..#...#",
        "#T.#.#.#",
        "#..#...#",
        "#......#",
        "#.##.#.#",
        "#T...T.#",
        "########",
    ),
    (
        "########",
        "#......#",
        "#.####.#",
        "#T....T#",
        "###.##.#",
        "#......#",
        "#.T....#",
        "########",
    ),
)

DIRECTIONS = {
    "w": (-1, 0),
    "a": (0, -1),
    "s": (1, 0),
    "d": (0, 1),
}

_last_maze = None


def initialize_game():
    """Choose a maze and create all state used during one game."""
    global _last_maze
    choices = [number for number in range(len(MAZES)) if number != _last_maze]
    maze_number = random.choice(choices)
    _last_maze = maze_number
    board = [list(row) for row in MAZES[maze_number]]
    return {
        "board": board,
        "maze_number": maze_number + 1,
        "player": PLAYER_START,
        "enemies": list(ENEMY_STARTS),
        "lives": STARTING_LIVES,
        "score": 0,
        "moves": 0,
        "treasures": 0,
        "exit": None,
    }


def show_instructions():
    print("\nTREASURE HUNT: KILLER MAZE")
    print("Collect all 3 treasures, then reach the exit.")
    print("Two killers chase you after every valid move.")
    print("Use W, A, S, and D to move. Enter Q to quit.")
    print("P = Player   K = Killer   T = Treasure   E = Exit   # = Wall")


def draw_game(state):
    """Draw a text version of the Bitmap Display game state."""
    board = state["board"]
    enemies = set(state["enemies"])
    print(f"\nMaze {state['maze_number']}")

    for row in range(8):
        displayed = []
        for column in range(8):
            position = (row, column)
            if position in enemies:
                displayed.append(KILLER)
            elif position == state["player"]:
                displayed.append(PLAYER)
            else:
                displayed.append(board[row][column])
        print(" ".join(displayed))

    print(
        f"\nLives: {state['lives']}   Score: {state['score']}   "
        f"Moves: {state['moves']}   Treasure: {state['treasures']}/3"
    )


def read_move():
    while True:
        choice = input("\nMove (W/A/S/D) or Q to quit: ").strip().lower()
        if choice in DIRECTIONS or choice == "q":
            return choice
        print("Invalid input. Please enter W, A, S, D, or Q.")


def is_open(board, position):
    row, column = position
    return 0 <= row < 8 and 0 <= column < 8 and board[row][column] != WALL


def spawn_exit(state):
    """Place the exit at a random unoccupied inner corner."""
    blocked = {state["player"], *state["enemies"]}
    choices = [corner for corner in EXIT_CORNERS if corner not in blocked]
    exit_position = random.choice(choices)
    row, column = exit_position
    state["board"][row][column] = EXIT
    state["exit"] = exit_position
    print("All treasures collected! An exit appeared in a random corner.")


def handle_current_tile(state):
    """Apply treasure or exit logic after the player moves."""
    row, column = state["player"]
    tile = state["board"][row][column]

    if tile == TREASURE:
        state["board"][row][column] = EMPTY
        state["treasures"] += 1
        state["score"] += TREASURE_POINTS
        print("You collected a treasure!")
        if state["treasures"] == 3:
            spawn_exit(state)
    elif tile == EXIT:
        return True

    return False


def choose_enemy_step(board, enemy, player, occupied):
    """Choose an open neighboring tile that gets closest to the player."""
    choices = []
    best_distance = 100

    for row_change, column_change in DIRECTIONS.values():
        candidate = (enemy[0] + row_change, enemy[1] + column_change)
        if not is_open(board, candidate):
            continue
        if candidate in occupied and candidate != player:
            continue

        distance = abs(candidate[0] - player[0]) + abs(candidate[1] - player[1])
        if distance < best_distance:
            best_distance = distance
            choices = [candidate]
        elif distance == best_distance:
            choices.append(candidate)

    return random.choice(choices) if choices else enemy


def move_enemies(state):
    """Move each killer one tile toward the player."""
    new_positions = []
    for index, enemy in enumerate(state["enemies"]):
        occupied = set(new_positions + state["enemies"][index + 1 :])
        new_enemy = choose_enemy_step(
            state["board"], enemy, state["player"], occupied
        )
        new_positions.append(new_enemy)
        if new_enemy == state["player"]:
            state["enemies"] = new_positions + state["enemies"][index + 1 :]
            return True

    state["enemies"] = new_positions
    return False


def handle_caught(state):
    """Remove a life and reset the characters unless no lives remain."""
    state["lives"] -= 1
    state["score"] = max(0, state["score"] - DEATH_PENALTY)
    print("A killer caught you! You lost one life.")

    if state["lives"] == 0:
        return True

    state["player"] = PLAYER_START
    state["enemies"] = list(ENEMY_STARTS)
    print("You and the killers returned to your starting positions.")
    return False


def process_move(state, choice):
    """Run one complete player turn and return win/loss status."""
    row_change, column_change = DIRECTIONS[choice]
    row, column = state["player"]
    new_position = (row + row_change, column + column_change)

    if not is_open(state["board"], new_position):
        print("A wall blocks that direction. Try another move.")
        return "continue"

    state["player"] = new_position
    state["moves"] += 1

    if new_position in state["enemies"]:
        return "loss" if handle_caught(state) else "continue"

    if handle_current_tile(state):
        return "win"

    if move_enemies(state):
        return "loss" if handle_caught(state) else "continue"

    return "continue"


def play_game():
    state = initialize_game()
    show_instructions()

    while True:
        draw_game(state)
        choice = read_move()

        if choice == "q":
            print("You ended the game.")
            return

        result = process_move(state, choice)
        if result == "win":
            exit_bonus = max(0, 300 - state["moves"] * 5)
            state["score"] += exit_bonus
            draw_game(state)
            print("\nYou escaped the killer maze!")
            print(f"Exit bonus: {exit_bonus}")
            print(f"Final score: {state['score']}")
            return
        if result == "loss":
            draw_game(state)
            print("\nYou lost all three lives. Game over!")
            return


def ask_play_again():
    while True:
        choice = input("\nPlay again? (Y/N): ").strip().lower()
        if choice in ("y", "n"):
            return choice == "y"
        print("Invalid input. Please enter Y or N.")


def main():
    while True:
        play_game()
        if not ask_play_again():
            print("Thanks for playing Treasure Hunt!")
            return


if __name__ == "__main__":
    main()
