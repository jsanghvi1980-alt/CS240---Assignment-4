"""Python planning/reference version of the MIPS Tic-Tac-Toe game."""

import random


WINNING_LINES = (
    (0, 1, 2),
    (3, 4, 5),
    (6, 7, 8),
    (0, 3, 6),
    (1, 4, 7),
    (2, 5, 8),
    (0, 4, 8),
    (2, 4, 6),
)


def get_game_mode():
    """Ask for one-player or two-player mode."""
    while True:
        choice = input("Enter 1 for one player or 2 for two players: ").strip()
        if choice in ("1", "2"):
            return int(choice)
        print("Please enter only 1 or 2.")


def show_board(board):
    """Print the current board and show numbers in unused positions."""
    display = []
    for index, value in enumerate(board):
        display.append(value if value != " " else str(index + 1))

    print()
    for row in range(3):
        start = row * 3
        print(f" {display[start]} | {display[start + 1]} | {display[start + 2]}")
        if row < 2:
            print("---+---+---")
    print()


def get_player_move(board, player):
    """Read and validate a human player's move."""
    while True:
        raw = input(f"Player {player}, enter a position from 1 to 9: ").strip()

        try:
            position = int(raw)
        except ValueError:
            print("Please enter a number from 1 to 9.")
            continue

        if position < 1 or position > 9:
            print("Please enter a number from 1 to 9.")
            continue

        index = position - 1
        if board[index] != " ":
            print("That position is already being used.")
            continue

        board[index] = player
        return


def get_bot_move(board):
    """Choose one random empty position for the computer."""
    print("The computer is choosing a position...")
    empty_positions = [index for index, value in enumerate(board) if value == " "]
    index = random.choice(empty_positions)
    board[index] = "O"
    print(f"The computer chose position {index + 1}.")


def check_winner(board):
    """Return X or O after a win, or None if nobody has won."""
    for first, second, third in WINNING_LINES:
        if board[first] != " " and board[first] == board[second] == board[third]:
            return board[first]
    return None


def change_player(player):
    """Change X to O or O to X."""
    return "O" if player == "X" else "X"


def play_game():
    """Run one complete Tic-Tac-Toe game."""
    print("\nTIC-TAC-TOE")
    print("Choose a numbered position. Player X goes first.\n")

    board = [" "] * 9
    game_mode = get_game_mode()
    current_player = "X"
    move_count = 0

    while True:
        show_board(board)

        if game_mode == 1 and current_player == "O":
            get_bot_move(board)
        else:
            get_player_move(board, current_player)

        move_count += 1
        winner = check_winner(board)

        if winner is not None:
            show_board(board)
            if game_mode == 1 and winner == "O":
                print("The computer wins!")
            else:
                print(f"Player {winner} wins!")
            return

        if move_count == 9:
            show_board(board)
            print("The game is a tie!")
            return

        current_player = change_player(current_player)


if __name__ == "__main__":
    play_game()
