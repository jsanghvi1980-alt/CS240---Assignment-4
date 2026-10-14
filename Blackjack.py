"""Python planning/reference version of the MIPS Blackjack game."""

import random


STARTING_BALANCE = 100
RANKS = ("A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K")
SUITS = ("H", "D", "C", "S")


def create_deck():
    """Create and shuffle the same 52 integer cards used by the MIPS game."""
    deck = list(range(52))
    random.shuffle(deck)
    return deck


def get_next_card(deck):
    """Remove and return the next card without repeating it."""
    return deck.pop()


def card_rank(card):
    return card % 13


def card_suit(card):
    return card // 13


def card_name(card):
    """Convert an integer card into a short name such as A-H or 10-S."""
    return f"{RANKS[card_rank(card)]}-{SUITS[card_suit(card)]}"


def print_cards(cards):
    print(" ".join(card_name(card) for card in cards))


def calculate_total(cards):
    """Calculate a hand total and reduce Aces from 11 to 1 when needed."""
    total = 0
    aces = 0

    for card in cards:
        rank = card_rank(card)
        if rank == 0:
            total += 11
            aces += 1
        elif rank >= 9:
            total += 10
        else:
            total += rank + 1

    while total > 21 and aces > 0:
        total -= 10
        aces -= 1

    return total


def read_yes_no(message):
    while True:
        choice = input(message).strip().lower()
        if choice in ("y", "n"):
            return choice == "y"
        print("Invalid choice. Please enter Y or N.")


def get_bet(balance):
    """Read a bet between 1 and the player's current balance."""
    while True:
        raw = input(f"\nCurrent balance: {balance}\nEnter your bet: ").strip()
        try:
            bet = int(raw)
        except ValueError:
            print("Your bet must be a whole number.")
            continue

        if 1 <= bet <= balance:
            return bet
        print("Your bet must be greater than 0 and cannot be more than your balance.")


def deal_starting_cards(deck):
    """Deal cards in player, dealer, player, dealer order."""
    player = [get_next_card(deck)]
    dealer = [get_next_card(deck)]
    player.append(get_next_card(deck))
    dealer.append(get_next_card(deck))
    return player, dealer


def show_starting_cards(player, dealer):
    print("\nYour cards: ", end="")
    print_cards(player)
    print(f"Your total: {calculate_total(player)}")
    print(f"Dealer is showing: {card_name(dealer[1])}")


def ask_split(player, deck, balance, bet):
    """Offer one split when the first two ranks match and funds allow it."""
    if card_rank(player[0]) != card_rank(player[1]) or 2 * bet > balance:
        return [player]

    if not read_yes_no("Your first two ranks match. Split them? (Y/N): "):
        return [player]

    hand1 = [player[0], get_next_card(deck)]
    hand2 = [player[1], get_next_card(deck)]
    print("The cards were split into two hands.")
    return [hand1, hand2]


def play_hand(hand, deck, hand_number, balance, bet):
    """Play one hand and return whether its wager was doubled."""
    first_choice = True
    doubled = False

    while True:
        total = calculate_total(hand)
        print(f"\nHand {hand_number}")
        print("Cards: ", end="")
        print_cards(hand)
        print(f"Total: {total}")

        if total == 21:
            print("Blackjack!")
            return doubled
        if total > 21:
            print("This hand went over 21.")
            return doubled

        prompt = "Enter H to hit, S to stand"
        if first_choice:
            prompt += ", or D to double"
        choice = input(prompt + ": ").strip().lower()

        if choice == "h":
            hand.append(get_next_card(deck))
            first_choice = False
            print("You received another card.")
        elif choice == "s":
            return doubled
        elif choice == "d" and first_choice:
            if 2 * bet > balance:
                print("You do not have enough points to double.")
            else:
                hand.append(get_next_card(deck))
                doubled = True
                print("You doubled and received one final card.")
                print("Cards: ", end="")
                print_cards(hand)
                return doubled
        else:
            print("Invalid choice. Please try again.")


def dealer_turn(dealer, deck):
    print("\nDealer's turn...")
    while calculate_total(dealer) < 17:
        dealer.append(get_next_card(deck))

    print("Dealer's cards: ", end="")
    print_cards(dealer)
    print(f"Dealer's total: {calculate_total(dealer)}")


def score_one_hand(hand, dealer, bet, doubled, statistics):
    """Score one hand, update statistics, and return the balance change."""
    wager = bet * 2 if doubled else bet
    player_total = calculate_total(hand)
    dealer_total = calculate_total(dealer)

    if player_total > 21:
        result = "Dealer wins this hand."
        change = -wager
        statistics["losses"] += 1
    elif dealer_total > 21:
        result = "Dealer went over 21. You win!"
        change = wager
        statistics["wins"] += 1
    elif player_total > dealer_total:
        result = "You win this hand!"
        change = wager
        statistics["wins"] += 1
    elif player_total < dealer_total:
        result = "Dealer wins this hand."
        change = -wager
        statistics["losses"] += 1
    else:
        result = "This hand is a tie."
        change = 0
        statistics["ties"] += 1

    print(result)
    print(f"Points changed by: {change}")
    return change


def check_natural_blackjack(player, dealer, bet, statistics):
    """Return the balance change when either starting hand is Blackjack."""
    player_natural = calculate_total(player) == 21
    dealer_natural = calculate_total(dealer) == 21

    if not player_natural and not dealer_natural:
        return None

    print("Dealer's cards: ", end="")
    print_cards(dealer)

    if player_natural and dealer_natural:
        print("You and the dealer both have Blackjack. It is a tie.")
        statistics["ties"] += 1
        return 0
    if player_natural:
        winnings = (3 * bet) // 2
        print("Natural Blackjack! You win 1.5 times your bet.")
        statistics["wins"] += 1
        return winnings

    print("Dealer has Blackjack. Dealer wins.")
    statistics["losses"] += 1
    return -bet


def print_statistics(balance, statistics):
    print("\nGame totals")
    print(f"Current balance: {balance}")
    print(f"Wins: {statistics['wins']}")
    print(f"Losses: {statistics['losses']}")
    print(f"Ties: {statistics['ties']}")


def play_round(balance, statistics):
    """Play one complete round and return the updated balance."""
    deck = create_deck()
    bet = get_bet(balance)
    player, dealer = deal_starting_cards(deck)
    show_starting_cards(player, dealer)

    natural_change = check_natural_blackjack(player, dealer, bet, statistics)
    if natural_change is not None:
        return balance + natural_change

    hands = ask_split(player, deck, balance, bet)
    doubled = []
    for index, hand in enumerate(hands, start=1):
        doubled.append(play_hand(hand, deck, index, balance, bet))

    if any(calculate_total(hand) <= 21 for hand in hands):
        dealer_turn(dealer, deck)
    else:
        print("\nDealer's cards: ", end="")
        print_cards(dealer)
        print(f"Dealer's total: {calculate_total(dealer)}")

    for index, hand in enumerate(hands):
        print(f"\nResult for hand {index + 1}")
        balance += score_one_hand(hand, dealer, bet, doubled[index], statistics)

    return balance


def main():
    print("\nREAL BLACKJACK")
    print("Get closer to 21 than the dealer without going over.")
    print("A is 11 or 1. J, Q, and K are worth 10.")

    balance = STARTING_BALANCE
    statistics = {"wins": 0, "losses": 0, "ties": 0}

    while balance > 0:
        balance = play_round(balance, statistics)
        print_statistics(balance, statistics)

        if balance <= 0:
            print("You have no points left. Game over.")
            break
        if not read_yes_no("\nPlay another round? (Y/N): "):
            break

    print("Thanks for playing!")


if __name__ == "__main__":
    main()
