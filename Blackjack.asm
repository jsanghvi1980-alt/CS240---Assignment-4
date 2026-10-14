.data

title:              .asciiz "\nREAL BLACKJACK\n"
instructions:       .asciiz "Get closer to 21 than the dealer without going over.\nA is 11 or 1. J, Q, and K are worth 10.\n"

inputModeMsg:       .asciiz "\nChoose input method (1 = Console, 2 = MMIO Keyboard): "
inputModeError:     .asciiz "Please enter only 1 or 2.\n"
consoleSelected:    .asciiz "Console input selected.\n"
mmioSelected:       .asciiz "MMIO keyboard selected.\nFor a bet, type the number and press Enter.\nFor letters, press one key without Enter.\n"

balanceMsg:         .asciiz "\nCurrent balance: "
betMsg:             .asciiz "\nEnter your bet: "
betError:           .asciiz "Your bet must be greater than 0 and cannot be more than your balance.\n"

playerCardsMsg:     .asciiz "\nYour cards: "
playerTotalMsg:     .asciiz "\nYour total: "
dealerShowingMsg:   .asciiz "\nDealer is showing: "
dealerCardsMsg:     .asciiz "\nDealer's cards: "
dealerTotalMsg:     .asciiz "\nDealer's total: "

handMsg:            .asciiz "\n\nHand "
cardsMsg:           .asciiz "\nCards: "
totalMsg:           .asciiz "\nTotal: "

choiceMsg:          .asciiz "\nEnter H to hit, S to stand, or D to double: "
hitStandMsg:        .asciiz "\nEnter H to hit or S to stand: "
invalidChoiceMsg:   .asciiz "Invalid choice. Please try again.\n"
cannotDoubleMsg:    .asciiz "You do not have enough points to double.\n"

splitMsg:           .asciiz "\nYour first two ranks match. Split them? (Y/N): "
splitDoneMsg:       .asciiz "\nThe cards were split into two hands.\n"

hitMsg:             .asciiz "\nYou received another card.\n"
doubleMsg:          .asciiz "\nYou doubled and received one final card.\n"
blackjackMsg:       .asciiz "\nBlackjack!\n"
bustMsg:            .asciiz "\nThis hand went over 21.\n"
dealerTurnMsg:      .asciiz "\n\nDealer's turn...\n"

playerWinMsg:       .asciiz "You win this hand!\n"
dealerWinMsg:       .asciiz "Dealer wins this hand.\n"
dealerBustMsg:      .asciiz "Dealer went over 21. You win!\n"
tieMsg:             .asciiz "This hand is a tie.\n"

naturalWinMsg:      .asciiz "\nNatural Blackjack! You win 1.5 times your bet.\n"
dealerNaturalMsg:   .asciiz "\nDealer has Blackjack. Dealer wins.\n"
bothNaturalMsg:     .asciiz "\nYou and the dealer both have Blackjack. It is a tie.\n"

resultMsg:          .asciiz "\nResult for hand "
pointsChangeMsg:    .asciiz "Points changed by: "

roundStatsMsg:      .asciiz "\n\nGame totals"
winsMsg:            .asciiz "\nWins: "
lossesMsg:          .asciiz "\nLosses: "
tiesMsg:            .asciiz "\nTies: "
playAgainMsg:       .asciiz "\n\nPlay another round? (Y/N): "
gameOverMsg:        .asciiz "\nYou have no points left. Game over.\n"
goodbyeMsg:         .asciiz "\nThanks for playing!\n"

dash:               .asciiz "-"
space:              .asciiz " "
newline:            .asciiz "\n"

# Shapes for 0-9, A, J, Q, and K
symbolRows:
.byte 7, 5, 5, 5, 7
.byte 2, 6, 2, 2, 7
.byte 7, 1, 7, 4, 7
.byte 7, 1, 7, 1, 7
.byte 5, 5, 7, 1, 1
.byte 7, 4, 7, 1, 7
.byte 7, 4, 7, 5, 7
.byte 7, 1, 1, 1, 1
.byte 7, 5, 7, 5, 7
.byte 7, 5, 7, 1, 7
.byte 2, 5, 7, 5, 5
.byte 1, 1, 1, 5, 7
.byte 7, 5, 5, 7, 1
.byte 5, 5, 6, 5, 5

inputBuffer:        .space 16

.align 2

inputMode:          .word 1
balance:            .word 100
currentBet:         .word 0

wins:               .word 0
losses:             .word 0
ties:               .word 0

deck:               .space 208
deckIndex:          .word 0

hand1:              .space 48
hand2:              .space 48
dealerHand:         .space 48

hand1Count:         .word 0
hand2Count:         .word 0
dealerCount:        .word 0

hand1Doubled:       .word 0
hand2Doubled:       .word 0
splitUsed:          .word 0
dealerHidden:       .word 1
dealerTotal:        .word 0


.text
.globl main


# Start the game
main:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, instructions
    syscall

    jal choose_input_mode


# Start a new round
round_start:
    lw $t0, balance
    blez $t0, no_points_left

    jal reset_round
    jal create_deck
    jal get_bet
    jal deal_starting_cards
    jal show_starting_cards
    jal check_natural_blackjack

    li $t0, 1
    beq $v0, $t0, round_finished

    jal ask_split

    la $a0, hand1
    lw $a1, hand1Count
    li $a2, 1
    jal play_hand

    sw $v0, hand1Doubled
    sw $v1, hand1Count

    lw $t0, splitUsed
    beq $t0, $zero, dealer_check

    la $a0, hand2
    lw $a1, hand2Count
    li $a2, 2
    jal play_hand

    sw $v0, hand2Doubled
    sw $v1, hand2Count


# Check whether the dealer needs to play
dealer_check:
    la $a0, hand1
    lw $a1, hand1Count
    jal calculate_total

    li $t0, 21
    ble $v0, $t0, dealer_turn

    lw $t1, splitUsed
    beq $t1, $zero, show_dealer_result

    la $a0, hand2
    lw $a1, hand2Count
    jal calculate_total

    li $t0, 21
    ble $v0, $t0, dealer_turn

    j show_dealer_result


# Play the dealer's turn
dealer_turn:
    sw $zero, dealerHidden
    jal draw_blackjack

    li $v0, 4
    la $a0, dealerTurnMsg
    syscall


dealer_draw_loop:
    la $a0, dealerHand
    lw $a1, dealerCount
    jal calculate_total

    li $t0, 17
    bge $v0, $t0, show_dealer_result

    jal get_next_card

    lw $t0, dealerCount
    sll $t1, $t0, 2

    la $t2, dealerHand
    add $t2, $t2, $t1
    sw $v0, 0($t2)

    addi $t0, $t0, 1
    sw $t0, dealerCount

    jal draw_blackjack
    j dealer_draw_loop


# Show the dealer's final cards
show_dealer_result:
    sw $zero, dealerHidden
    jal draw_blackjack

    li $v0, 4
    la $a0, dealerCardsMsg
    syscall

    la $a0, dealerHand
    lw $a1, dealerCount
    jal print_cards

    la $a0, dealerHand
    lw $a1, dealerCount
    jal calculate_total

    sw $v0, dealerTotal
    move $t0, $v0

    li $v0, 4
    la $a0, dealerTotalMsg
    syscall

    move $a0, $t0
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    jal score_player_hands


# Finish the current round
round_finished:
    jal print_statistics
    jal ask_play_again

    li $t0, 1
    beq $v0, $t0, round_start

    j finish_game


# End when the balance reaches zero
no_points_left:
    li $v0, 4
    la $a0, gameOverMsg
    syscall


# Finish the program
finish_game:
    li $v0, 4
    la $a0, goodbyeMsg
    syscall

    li $v0, 10
    syscall


# Choose console or MMIO input
choose_input_mode:

ask_input_mode:
    li $v0, 4
    la $a0, inputModeMsg
    syscall

    li $v0, 5
    syscall

    move $t0, $v0

    li $t1, 1
    beq $t0, $t1, choose_console

    li $t1, 2
    beq $t0, $t1, choose_mmio

    li $v0, 4
    la $a0, inputModeError
    syscall

    j ask_input_mode


# Save console input mode
choose_console:
    li $t0, 1
    sw $t0, inputMode

    li $v0, 4
    la $a0, consoleSelected
    syscall

    jr $ra


# Save MMIO input mode
choose_mmio:
    li $t0, 2
    sw $t0, inputMode

    li $v0, 4
    la $a0, mmioSelected
    syscall

    jr $ra


# Read one letter
read_character:
    lw $t0, inputMode

    li $t1, 1
    beq $t0, $t1, read_console_character


read_mmio_character:
    li $t0, 0xffff0000
    lw $t1, 0($t0)

    andi $t1, $t1, 1
    beq $t1, $zero, read_mmio_character

    li $t0, 0xffff0004
    lw $t2, 0($t0)
    andi $t2, $t2, 0x00ff

    li $t3, 10
    beq $t2, $t3, read_mmio_character

    li $t3, 13
    beq $t2, $t3, read_mmio_character

    li $t3, 65
    blt $t2, $t3, mmio_character_ready

    li $t3, 90
    bgt $t2, $t3, mmio_character_ready

    addi $t2, $t2, 32


mmio_character_ready:
    move $t3, $t2

    move $a0, $t2
    li $v0, 11
    syscall

    li $a0, 10
    li $v0, 11
    syscall

    move $v0, $t3
    jr $ra


# Read a letter from the console
read_console_character:
    li $v0, 8
    la $a0, inputBuffer
    li $a1, 16
    syscall

    la $t0, inputBuffer
    lb $t1, 0($t0)

    li $t2, 65
    blt $t1, $t2, console_character_ready

    li $t2, 90
    bgt $t1, $t2, console_character_ready

    addi $t1, $t1, 32


console_character_ready:
    move $v0, $t1
    jr $ra


# Read a full number
read_number:
    lw $t0, inputMode

    li $t1, 1
    beq $t0, $t1, read_console_number

    li $t4, 0
    li $t5, 0


read_mmio_number:
    li $t0, 0xffff0000
    lw $t1, 0($t0)

    andi $t1, $t1, 1
    beq $t1, $zero, read_mmio_number

    li $t0, 0xffff0004
    lw $t2, 0($t0)
    andi $t2, $t2, 0x00ff

    li $t3, 10
    beq $t2, $t3, finish_mmio_number

    li $t3, 13
    beq $t2, $t3, finish_mmio_number

    li $t3, 48
    blt $t2, $t3, read_mmio_number

    li $t3, 57
    bgt $t2, $t3, read_mmio_number

    move $t6, $t2

    move $a0, $t2
    li $v0, 11
    syscall

    move $t2, $t6
    addi $t2, $t2, -48

    li $t3, 10
    mul $t4, $t4, $t3
    add $t4, $t4, $t2

    li $t5, 1
    j read_mmio_number


finish_mmio_number:
    beq $t5, $zero, read_mmio_number

    li $a0, 10
    li $v0, 11
    syscall

    move $v0, $t4
    jr $ra


# Read a number from the console
read_console_number:
    li $v0, 5
    syscall

    jr $ra


# Reset values for a new round
reset_round:
    sw $zero, hand1Count
    sw $zero, hand2Count
    sw $zero, dealerCount

    sw $zero, hand1Doubled
    sw $zero, hand2Doubled
    sw $zero, splitUsed
    sw $zero, dealerTotal
    sw $zero, deckIndex

    li $t0, 1
    sw $t0, dealerHidden

    jr $ra


# Create and shuffle the deck
create_deck:
    la $t0, deck
    li $t1, 0


fill_deck_loop:
    li $t2, 52
    beq $t1, $t2, start_shuffle

    sw $t1, 0($t0)

    addi $t0, $t0, 4
    addi $t1, $t1, 1

    j fill_deck_loop


start_shuffle:
    li $t0, 51


shuffle_loop:
    blez $t0, shuffle_finished

    addi $t1, $t0, 1

    li $v0, 42
    li $a0, 0
    move $a1, $t1
    syscall

    move $t2, $a0

    sll $t3, $t0, 2
    la $t4, deck
    add $t3, $t4, $t3

    sll $t5, $t2, 2
    add $t5, $t4, $t5

    lw $t6, 0($t3)
    lw $t7, 0($t5)

    sw $t7, 0($t3)
    sw $t6, 0($t5)

    addi $t0, $t0, -1
    j shuffle_loop


shuffle_finished:
    jr $ra


# Get the next card
get_next_card:
    lw $t0, deckIndex

    sll $t1, $t0, 2
    la $t2, deck
    add $t2, $t2, $t1

    lw $v0, 0($t2)

    addi $t0, $t0, 1
    sw $t0, deckIndex

    jr $ra


# Ask the player for a bet
get_bet:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


ask_bet:
    li $v0, 4
    la $a0, balanceMsg
    syscall

    lw $a0, balance
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, betMsg
    syscall

    jal read_number

    move $t0, $v0

    blez $t0, invalid_bet

    lw $t1, balance
    bgt $t0, $t1, invalid_bet

    sw $t0, currentBet

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


invalid_bet:
    li $v0, 4
    la $a0, betError
    syscall

    j ask_bet


# Deal two cards to each side
deal_starting_cards:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal get_next_card
    la $t0, hand1
    sw $v0, 0($t0)

    jal get_next_card
    la $t0, dealerHand
    sw $v0, 0($t0)

    jal get_next_card
    la $t0, hand1
    sw $v0, 4($t0)

    jal get_next_card
    la $t0, dealerHand
    sw $v0, 4($t0)

    li $t0, 2
    sw $t0, hand1Count
    sw $t0, dealerCount

    jal draw_blackjack

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Show the starting cards
show_starting_cards:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4
    la $a0, playerCardsMsg
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    jal print_cards

    li $v0, 4
    la $a0, playerTotalMsg
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    jal calculate_total

    move $a0, $v0
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, dealerShowingMsg
    syscall

    la $t0, dealerHand
    lw $a0, 4($t0)
    jal print_card

    li $v0, 4
    la $a0, newline
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Check for natural Blackjack
check_natural_blackjack:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    la $a0, hand1
    li $a1, 2
    jal calculate_total

    move $s0, $v0

    la $a0, dealerHand
    li $a1, 2
    jal calculate_total

    move $s1, $v0

    li $t0, 21
    beq $s0, $t0, player_has_natural
    beq $s1, $t0, dealer_only_natural

    li $v0, 0
    j natural_check_done


player_has_natural:
    li $t0, 21
    beq $s1, $t0, both_have_natural

    li $v0, 4
    la $a0, naturalWinMsg
    syscall

    lw $t0, currentBet
    li $t1, 3
    mul $t0, $t0, $t1

    li $t1, 2
    div $t0, $t1
    mflo $t0

    lw $t1, balance
    add $t1, $t1, $t0
    sw $t1, balance

    lw $t1, wins
    addi $t1, $t1, 1
    sw $t1, wins

    jal print_dealer_cards

    li $v0, 1
    j natural_check_done


dealer_only_natural:
    li $v0, 4
    la $a0, dealerNaturalMsg
    syscall

    lw $t0, currentBet
    lw $t1, balance
    sub $t1, $t1, $t0
    sw $t1, balance

    lw $t1, losses
    addi $t1, $t1, 1
    sw $t1, losses

    jal print_dealer_cards

    li $v0, 1
    j natural_check_done


both_have_natural:
    li $v0, 4
    la $a0, bothNaturalMsg
    syscall

    lw $t1, ties
    addi $t1, $t1, 1
    sw $t1, ties

    jal print_dealer_cards

    li $v0, 1


natural_check_done:
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16

    jr $ra


# Ask whether to split
ask_split:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    la $t0, hand1
    lw $t1, 0($t0)
    lw $t2, 4($t0)

    li $t3, 13

    div $t1, $t3
    mfhi $t4

    div $t2, $t3
    mfhi $t5

    bne $t4, $t5, split_not_used

    lw $t0, currentBet
    sll $t0, $t0, 1

    lw $t1, balance
    bgt $t0, $t1, split_not_used


split_question:
    li $v0, 4
    la $a0, splitMsg
    syscall

    jal read_character

    move $s0, $v0

    li $t0, 121
    beq $s0, $t0, make_split

    li $t0, 110
    beq $s0, $t0, split_not_used

    li $v0, 4
    la $a0, invalidChoiceMsg
    syscall

    j split_question


make_split:
    li $t0, 1
    sw $t0, splitUsed

    la $t0, hand1
    lw $t1, 4($t0)

    la $t2, hand2
    sw $t1, 0($t2)

    li $t3, 1
    sw $t3, hand1Count
    sw $t3, hand2Count

    jal get_next_card

    la $t0, hand1
    sw $v0, 4($t0)

    jal get_next_card

    la $t0, hand2
    sw $v0, 4($t0)

    li $t0, 2
    sw $t0, hand1Count
    sw $t0, hand2Count

    li $v0, 4
    la $a0, splitDoneMsg
    syscall

    jal draw_blackjack


split_not_used:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    jr $ra


# Play one player hand
play_hand:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    li $s3, 1
    li $s4, 0


player_hand_loop:
    li $v0, 4
    la $a0, handMsg
    syscall

    move $a0, $s2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, cardsMsg
    syscall

    move $a0, $s0
    move $a1, $s1
    jal print_cards

    li $v0, 4
    la $a0, totalMsg
    syscall

    move $a0, $s0
    move $a1, $s1
    jal calculate_total

    move $t0, $v0

    move $a0, $t0
    li $v0, 1
    syscall

    li $t1, 21
    beq $t0, $t1, hand_is_21
    bgt $t0, $t1, hand_busted

    beq $s3, $zero, only_hit_or_stand

    li $v0, 4
    la $a0, choiceMsg
    syscall

    j read_hand_choice


only_hit_or_stand:
    li $v0, 4
    la $a0, hitStandMsg
    syscall


read_hand_choice:
    jal read_character

    move $t0, $v0

    li $t1, 104
    beq $t0, $t1, player_hits

    li $t1, 115
    beq $t0, $t1, player_stands

    li $t1, 100
    bne $t0, $t1, bad_hand_choice

    beq $s3, $zero, bad_hand_choice

    j player_doubles


bad_hand_choice:
    li $v0, 4
    la $a0, invalidChoiceMsg
    syscall

    j player_hand_loop


# Give the player another card
player_hits:
    jal get_next_card

    sll $t0, $s1, 2
    add $t0, $s0, $t0
    sw $v0, 0($t0)

    addi $s1, $s1, 1
    li $s3, 0

    li $t0, 1
    beq $s2, $t0, save_hit_hand1

    sw $s1, hand2Count
    j hit_count_saved


save_hit_hand1:
    sw $s1, hand1Count


hit_count_saved:
    jal draw_blackjack

    li $v0, 4
    la $a0, hitMsg
    syscall

    j player_hand_loop


# Double the wager and take one card
player_doubles:
    lw $t0, currentBet
    sll $t0, $t0, 1

    lw $t1, balance
    bgt $t0, $t1, cannot_double

    jal get_next_card

    sll $t0, $s1, 2
    add $t0, $s0, $t0
    sw $v0, 0($t0)

    addi $s1, $s1, 1
    li $s4, 1

    li $t0, 1
    beq $s2, $t0, save_double_hand1

    sw $s1, hand2Count
    j double_count_saved


save_double_hand1:
    sw $s1, hand1Count


double_count_saved:
    jal draw_blackjack

    li $v0, 4
    la $a0, doubleMsg
    syscall

    move $a0, $s0
    move $a1, $s1
    jal print_cards

    j finish_player_hand


cannot_double:
    li $v0, 4
    la $a0, cannotDoubleMsg
    syscall

    j player_hand_loop


# Stop taking cards
player_stands:
    j finish_player_hand


# Stop when the hand reaches 21
hand_is_21:
    li $v0, 4
    la $a0, blackjackMsg
    syscall

    j finish_player_hand


# Stop when the hand goes over 21
hand_busted:
    li $v0, 4
    la $a0, bustMsg
    syscall


finish_player_hand:
    move $v0, $s4
    move $v1, $s1

    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28

    jr $ra


# Calculate one hand's total
calculate_total:
    li $t0, 0
    li $t1, 0
    li $t2, 0


calculate_loop:
    beq $t0, $a1, adjust_hand_aces

    lw $t3, 0($a0)

    li $t4, 13
    div $t3, $t4
    mfhi $t5

    beq $t5, $zero, value_is_ace

    li $t6, 9
    bge $t5, $t6, value_is_ten

    addi $t5, $t5, 1
    add $t1, $t1, $t5

    j next_total_card


value_is_ace:
    addi $t1, $t1, 11
    addi $t2, $t2, 1

    j next_total_card


value_is_ten:
    addi $t1, $t1, 10


next_total_card:
    addi $a0, $a0, 4
    addi $t0, $t0, 1
    j calculate_loop


adjust_hand_aces:
    li $t3, 21
    ble $t1, $t3, total_ready

    beq $t2, $zero, total_ready

    addi $t1, $t1, -10
    addi $t2, $t2, -1

    j adjust_hand_aces


total_ready:
    move $v0, $t1
    jr $ra


# Print every card in a hand
print_cards:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)

    move $s0, $a0
    move $s1, $a1
    li $s2, 0


print_cards_loop:
    beq $s2, $s1, print_cards_done

    lw $a0, 0($s0)
    jal print_card

    li $v0, 4
    la $a0, space
    syscall

    addi $s0, $s0, 4
    addi $s2, $s2, 1

    j print_cards_loop


print_cards_done:
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20

    jr $ra


# Print one card's rank and suit
print_card:
    move $t0, $a0

    li $t1, 13
    div $t0, $t1

    mflo $t2
    mfhi $t3

    beq $t3, $zero, print_rank_ace

    li $t4, 9
    beq $t3, $t4, print_rank_ten

    li $t4, 10
    beq $t3, $t4, print_rank_jack

    li $t4, 11
    beq $t3, $t4, print_rank_queen

    li $t4, 12
    beq $t3, $t4, print_rank_king

    addi $a0, $t3, 1
    li $v0, 1
    syscall

    j print_card_suit


print_rank_ace:
    li $a0, 65
    li $v0, 11
    syscall

    j print_card_suit


print_rank_ten:
    li $a0, 10
    li $v0, 1
    syscall

    j print_card_suit


print_rank_jack:
    li $a0, 74
    li $v0, 11
    syscall

    j print_card_suit


print_rank_queen:
    li $a0, 81
    li $v0, 11
    syscall

    j print_card_suit


print_rank_king:
    li $a0, 75
    li $v0, 11
    syscall


print_card_suit:
    li $v0, 4
    la $a0, dash
    syscall

    beq $t2, $zero, print_hearts

    li $t4, 1
    beq $t2, $t4, print_diamonds

    li $t4, 2
    beq $t2, $t4, print_clubs

    li $a0, 83
    li $v0, 11
    syscall

    jr $ra


print_hearts:
    li $a0, 72
    li $v0, 11
    syscall
    jr $ra


print_diamonds:
    li $a0, 68
    li $v0, 11
    syscall
    jr $ra


print_clubs:
    li $a0, 67
    li $v0, 11
    syscall
    jr $ra


# Print every dealer card
print_dealer_cards:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    sw $zero, dealerHidden
    jal draw_blackjack

    li $v0, 4
    la $a0, dealerCardsMsg
    syscall

    la $a0, dealerHand
    lw $a1, dealerCount
    jal print_cards

    li $v0, 4
    la $a0, newline
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra


# Score both player hands
score_player_hands:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4
    la $a0, resultMsg
    syscall

    li $a0, 1
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    lw $a2, hand1Doubled
    jal score_one_hand

    lw $t0, splitUsed
    beq $t0, $zero, scoring_done

    li $v0, 4
    la $a0, resultMsg
    syscall

    li $a0, 2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    la $a0, hand2
    lw $a1, hand2Count
    lw $a2, hand2Doubled
    jal score_one_hand


scoring_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Score one player hand
score_one_hand:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2

    move $a0, $s0
    move $a1, $s1
    jal calculate_total

    move $s3, $v0
    lw $s1, currentBet

    beq $s2, $zero, wager_ready
    sll $s1, $s1, 1


wager_ready:
    li $t0, 21
    bgt $s3, $t0, dealer_wins_hand

    lw $t1, dealerTotal
    bgt $t1, $t0, player_wins_hand

    bgt $s3, $t1, player_wins_hand
    blt $s3, $t1, dealer_wins_hand

    li $v0, 4
    la $a0, tieMsg
    syscall

    lw $t0, ties
    addi $t0, $t0, 1
    sw $t0, ties

    li $t2, 0
    j show_point_change


player_wins_hand:
    lw $t1, dealerTotal

    li $t0, 21
    bgt $t1, $t0, print_dealer_bust

    li $v0, 4
    la $a0, playerWinMsg
    syscall

    j add_winning_points


print_dealer_bust:
    li $v0, 4
    la $a0, dealerBustMsg
    syscall


add_winning_points:
    lw $t0, balance
    add $t0, $t0, $s1
    sw $t0, balance

    lw $t0, wins
    addi $t0, $t0, 1
    sw $t0, wins

    move $t2, $s1
    j show_point_change


dealer_wins_hand:
    li $v0, 4
    la $a0, dealerWinMsg
    syscall

    lw $t0, balance
    sub $t0, $t0, $s1
    sw $t0, balance

    lw $t0, losses
    addi $t0, $t0, 1
    sw $t0, losses

    sub $t2, $zero, $s1


show_point_change:
    li $v0, 4
    la $a0, pointsChangeMsg
    syscall

    move $a0, $t2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


# Print the balance and statistics
print_statistics:
    li $v0, 4
    la $a0, roundStatsMsg
    syscall

    li $v0, 4
    la $a0, balanceMsg
    syscall

    lw $a0, balance
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, winsMsg
    syscall

    lw $a0, wins
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, lossesMsg
    syscall

    lw $a0, losses
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, tiesMsg
    syscall

    lw $a0, ties
    li $v0, 1
    syscall

    jr $ra


# Ask whether to play another round
ask_play_again:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


play_again_question:
    li $v0, 4
    la $a0, playAgainMsg
    syscall

    jal read_character

    li $t0, 121
    beq $v0, $t0, play_again_yes

    li $t0, 110
    beq $v0, $t0, play_again_no

    li $v0, 4
    la $a0, invalidChoiceMsg
    syscall

    j play_again_question


play_again_yes:
    li $v0, 1
    j play_again_done


play_again_no:
    li $v0, 0


play_again_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Redraw the complete Blackjack table
draw_blackjack:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)

    jal clear_blackjack_display

    lw $s0, dealerCount
    li $s1, 0
    la $s3, dealerHand


draw_dealer_cards:
    beq $s1, $s0, start_player_cards

    li $t0, 7
    beq $s1, $t0, start_player_cards

    li $t0, 9
    mul $a0, $s1, $t0
    addi $a0, $a0, 1

    li $a1, 1

    lw $t1, dealerHidden
    beq $t1, $zero, visible_dealer_card
    bne $s1, $zero, visible_dealer_card

    li $a2, 0x00aa0000
    li $a3, -1
    jal draw_bitmap_card

    j next_dealer_card


visible_dealer_card:
    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    li $a2, 0x00ffffff
    jal draw_bitmap_card


next_dealer_card:
    addi $s1, $s1, 1
    j draw_dealer_cards


# Start drawing the first player hand
start_player_cards:
    lw $s0, hand1Count
    li $s1, 0
    la $s3, hand1

    lw $t0, splitUsed
    beq $t0, $zero, hand1_normal_row

    li $s2, 12
    j draw_hand1_cards


hand1_normal_row:
    li $s2, 22


draw_hand1_cards:
    beq $s1, $s0, check_second_hand

    li $t0, 7
    beq $s1, $t0, check_second_hand

    li $t0, 9
    mul $a0, $s1, $t0
    addi $a0, $a0, 1

    move $a1, $s2
    li $a2, 0x00ffffff

    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    jal draw_bitmap_card

    addi $s1, $s1, 1
    j draw_hand1_cards


# Draw the second hand after splitting
check_second_hand:
    lw $t0, splitUsed
    beq $t0, $zero, blackjack_drawing_done

    lw $s0, hand2Count
    li $s1, 0
    la $s3, hand2


draw_hand2_cards:
    beq $s1, $s0, blackjack_drawing_done

    li $t0, 7
    beq $s1, $t0, blackjack_drawing_done

    li $t0, 9
    mul $a0, $s1, $t0
    addi $a0, $a0, 1

    li $a1, 22
    li $a2, 0x00dddddd

    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    jal draw_bitmap_card

    addi $s1, $s1, 1
    j draw_hand2_cards


blackjack_drawing_done:
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28

    jr $ra


# Clear the Bitmap Display
clear_blackjack_display:
    move $t0, $gp
    li $t1, 2048
    li $t2, 0x00006622


clear_blackjack_loop:
    beq $t1, $zero, clear_blackjack_done

    sw $t2, 0($t0)

    addi $t0, $t0, 4
    addi $t1, $t1, -1

    j clear_blackjack_loop


clear_blackjack_done:
    jr $ra


# Draw one card on the Bitmap Display
draw_bitmap_card:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3

    li $t3, 0


bitmap_card_row:
    li $t4, 9
    beq $t3, $t4, bitmap_card_ready

    li $t5, 0


bitmap_card_column:
    li $t4, 8
    beq $t5, $t4, next_bitmap_card_row

    add $t6, $s0, $t5
    add $t7, $s1, $t3

    sll $t8, $t7, 6
    add $t8, $t8, $t6
    sll $t8, $t8, 2
    add $t8, $gp, $t8

    sw $s2, 0($t8)

    addi $t5, $t5, 1
    j bitmap_card_column


next_bitmap_card_row:
    addi $t3, $t3, 1
    j bitmap_card_row


bitmap_card_ready:
    bltz $s3, bitmap_card_done

    li $t0, 13
    div $s3, $t0

    mflo $t1
    mfhi $t2

    li $s4, 0x00000000

    li $t3, 2
    bge $t1, $t3, bitmap_color_ready

    li $s4, 0x00cc0000


bitmap_color_ready:
    beq $t2, $zero, bitmap_rank_ace

    li $t3, 9
    beq $t2, $t3, bitmap_rank_ten

    li $t3, 10
    beq $t2, $t3, bitmap_rank_jack

    li $t3, 11
    beq $t2, $t3, bitmap_rank_queen

    li $t3, 12
    beq $t2, $t3, bitmap_rank_king

    addi $a2, $t2, 1

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    move $a3, $s4
    jal draw_bitmap_symbol

    j bitmap_card_done


bitmap_rank_ace:
    li $a2, 10
    j draw_one_bitmap_rank


bitmap_rank_jack:
    li $a2, 11
    j draw_one_bitmap_rank


bitmap_rank_queen:
    li $a2, 12
    j draw_one_bitmap_rank


bitmap_rank_king:
    li $a2, 13


draw_one_bitmap_rank:
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    move $a3, $s4
    jal draw_bitmap_symbol

    j bitmap_card_done


bitmap_rank_ten:
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    li $a2, 1
    move $a3, $s4
    jal draw_bitmap_symbol

    addi $a0, $s0, 4
    addi $a1, $s1, 2
    li $a2, 0
    move $a3, $s4
    jal draw_bitmap_symbol


bitmap_card_done:
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28

    jr $ra


# Draw one rank symbol
draw_bitmap_symbol:
    move $t0, $a0
    move $t1, $a1

    li $t2, 5
    mul $t2, $a2, $t2

    la $t3, symbolRows
    add $t3, $t3, $t2

    li $t4, 0


bitmap_symbol_row:
    li $t5, 5
    beq $t4, $t5, bitmap_symbol_done

    lbu $t6, 0($t3)
    li $t7, 0


bitmap_symbol_column:
    li $t5, 3
    beq $t7, $t5, next_bitmap_symbol_row

    li $t8, 2
    sub $t8, $t8, $t7

    li $t9, 1
    sllv $t9, $t9, $t8

    and $t9, $t6, $t9
    beq $t9, $zero, skip_bitmap_pixel

    add $t8, $t0, $t7
    add $t9, $t1, $t4

    sll $t9, $t9, 6
    add $t9, $t9, $t8
    sll $t9, $t9, 2
    add $t9, $gp, $t9

    sw $a3, 0($t9)


skip_bitmap_pixel:
    addi $t7, $t7, 1
    j bitmap_symbol_column


next_bitmap_symbol_row:
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j bitmap_symbol_row


bitmap_symbol_done:
    jr $ra