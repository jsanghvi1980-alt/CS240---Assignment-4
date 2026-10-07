.data

title:          .asciiz "\nBLACKJACK\n"
instructions:   .asciiz "Try to get close to 21 without going over.\nA is worth 11, but changes to 1 when needed.\nA normal game is worth 10 points.\nA doubled game is worth 20 points.\n"

yourCards:      .asciiz "\nYour cards: "
yourTotal:      .asciiz "\nYour total: "
dealerShowing:  .asciiz "\nDealer is showing: "
dealerTurnMsg:  .asciiz "\n\nDealer's turn...\n"
dealerCardsMsg: .asciiz "\nDealer's cards: "
dealerTotalMsg: .asciiz "\nDealer's total: "

handMessage:    .asciiz "\n\nHand "
cardsMessage:   .asciiz "\nCards: "
totalMessage:   .asciiz "\nTotal: "

choiceMessage:  .asciiz "\nEnter H to hit, S to stand, or D to double: "
hitStandMsg:    .asciiz "\nEnter H to hit or S to stand: "
invalidChoice:  .asciiz "Invalid input. Please try again.\n"

splitMessage:   .asciiz "\nYour cards match. Split them? (Y/N): "
splitMadeMsg:   .asciiz "\nYour cards were split into two hands.\n"

blackjackMsg:   .asciiz "\nYou got 21!\n"
bustMessage:    .asciiz "\nThis hand went over 21.\n"
doubleMessage:  .asciiz "\nYou doubled, so you must stand.\n"

playerWinsMsg:  .asciiz "You win this hand!\n"
dealerWinsMsg:  .asciiz "Dealer wins this hand.\n"
dealerBustMsg:  .asciiz "Dealer went over 21. You win this hand!\n"
tieMessage:     .asciiz "This hand is a tie.\n"

resultMessage:  .asciiz "\nResult for hand "
finalScoreMsg:  .asciiz "\nYour final score is: "

newline:        .asciiz "\n"
space:          .asciiz " "
aceText:        .asciiz "A"

# Shapes for 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, and A
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

inputBuffer:    .space 8

.align 2

hand1:          .space 48
hand2:          .space 48
dealerHand:     .space 48

hand1Count:     .word 0
hand2Count:     .word 0
dealerCount:    .word 0

hand1Doubled:   .word 0
hand2Doubled:   .word 0

splitUsed:      .word 0
dealerHidden:   .word 1
dealerTotal:    .word 0
score:          .word 0


.text
.globl main

main:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, instructions
    syscall

    # Give player two cards
    jal get_card
    la $t0, hand1
    sw $v0, 0($t0)

    jal get_card
    la $t0, hand1
    sw $v0, 4($t0)

    li $t1, 2
    sw $t1, hand1Count

    # Give dealer two cards
    jal get_card
    la $t0, dealerHand
    sw $v0, 0($t0)

    jal get_card
    la $t0, dealerHand
    sw $v0, 4($t0)

    li $t1, 2
    sw $t1, dealerCount

    # Draw starting table
    jal draw_blackjack

    # Show player's cards
    li $v0, 4
    la $a0, yourCards
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    jal print_cards

    # Show player's total
    li $v0, 4
    la $a0, yourTotal
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    jal calculate_total

    move $a0, $v0
    li $v0, 1
    syscall

    # Show one dealer card
    li $v0, 4
    la $a0, dealerShowing
    syscall

    la $t0, dealerHand
    lw $t3, 4($t0)

    li $t4, 11
    beq $t3, $t4, show_dealer_ace

    move $a0, $t3
    li $v0, 1
    syscall

    j check_for_split


show_dealer_ace:
    li $v0, 4
    la $a0, aceText
    syscall


check_for_split:
    la $t0, hand1
    lw $t1, 0($t0)
    lw $t2, 4($t0)

    bne $t1, $t2, play_first_hand


ask_split:
    li $v0, 4
    la $a0, splitMessage
    syscall

    jal read_choice

    li $t0, 121
    beq $v0, $t0, make_split

    li $t0, 110
    beq $v0, $t0, play_first_hand

    li $v0, 4
    la $a0, invalidChoice
    syscall

    j ask_split


make_split:
    li $t0, 1
    sw $t0, splitUsed

    # Move second matching card to hand 2
    la $t1, hand1
    lw $t2, 4($t1)

    la $t3, hand2
    sw $t2, 0($t3)

    # Give hand 1 a new card
    jal get_card
    la $t1, hand1
    sw $v0, 4($t1)

    # Give hand 2 a new card
    jal get_card
    la $t3, hand2
    sw $v0, 4($t3)

    li $t0, 2
    sw $t0, hand1Count
    sw $t0, hand2Count

    li $v0, 4
    la $a0, splitMadeMsg
    syscall

    jal draw_blackjack


play_first_hand:
    la $a0, hand1
    lw $a1, hand1Count
    li $a2, 1
    jal play_hand

    sw $v0, hand1Doubled
    sw $v1, hand1Count

    lw $t0, splitUsed
    beq $t0, $zero, dealer_turn_check

    la $a0, hand2
    lw $a1, hand2Count
    li $a2, 2
    jal play_hand

    sw $v0, hand2Doubled
    sw $v1, hand2Count


dealer_turn_check:
    la $a0, hand1
    lw $a1, hand1Count
    jal calculate_total

    move $t0, $v0

    li $t1, 21
    ble $t0, $t1, dealer_turn

    lw $t2, splitUsed
    beq $t2, $zero, show_dealer

    la $a0, hand2
    lw $a1, hand2Count
    jal calculate_total

    move $t0, $v0

    li $t1, 21
    ble $t0, $t1, dealer_turn

    j show_dealer


dealer_turn:
    # Reveal dealer cards
    li $t0, 0
    sw $t0, dealerHidden
    jal draw_blackjack

    li $v0, 4
    la $a0, dealerTurnMsg
    syscall


dealer_loop:
    la $a0, dealerHand
    lw $a1, dealerCount
    jal calculate_total

    li $t0, 17
    bge $v0, $t0, show_dealer

    # Give dealer another card
    jal get_card

    lw $t1, dealerCount
    sll $t2, $t1, 2

    la $t3, dealerHand
    add $t3, $t3, $t2
    sw $v0, 0($t3)

    addi $t1, $t1, 1
    sw $t1, dealerCount

    jal draw_blackjack

    j dealer_loop


show_dealer:
    li $t0, 0
    sw $t0, dealerHidden
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


score_first_hand:
    li $v0, 4
    la $a0, resultMessage
    syscall

    li $v0, 1
    li $a0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    la $a0, hand1
    lw $a1, hand1Count
    lw $a2, hand1Doubled
    jal score_hand

    sw $v0, score

    lw $t0, splitUsed
    beq $t0, $zero, print_final_score


score_second_hand:
    li $v0, 4
    la $a0, resultMessage
    syscall

    li $v0, 1
    li $a0, 2
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    la $a0, hand2
    lw $a1, hand2Count
    lw $a2, hand2Doubled
    jal score_hand

    lw $t0, score
    add $t0, $t0, $v0
    sw $t0, score


print_final_score:
    li $v0, 4
    la $a0, finalScoreMsg
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 10
    syscall


# =========================================================
# GAME PROCEDURES
# =========================================================

get_card:
    # Generate random number from 0 through 12
    li $v0, 42
    li $a0, 0
    li $a1, 13
    syscall

    # Change to 1 through 13
    addi $t0, $a0, 1

    # Ace
    li $t1, 1
    beq $t0, $t1, card_is_ace

    # 10, Jack, Queen, and King
    li $t1, 10
    bge $t0, $t1, card_is_ten

    move $v0, $t0
    jr $ra


card_is_ace:
    li $v0, 11
    jr $ra


card_is_ten:
    li $v0, 10
    jr $ra


read_choice:
    li $v0, 8
    la $a0, inputBuffer
    li $a1, 8
    syscall

    la $t0, inputBuffer
    lb $v0, 0($t0)

    # Convert uppercase to lowercase
    li $t1, 65
    blt $v0, $t1, choice_done

    li $t1, 90
    bgt $v0, $t1, choice_done

    addi $v0, $v0, 32


choice_done:
    jr $ra


calculate_total:
    li $t0, 0
    li $t1, 0
    li $t2, 0


total_loop:
    beq $t0, $a1, adjust_aces

    lw $t3, 0($a0)
    add $t1, $t1, $t3

    li $t4, 11
    bne $t3, $t4, not_an_ace

    addi $t2, $t2, 1


not_an_ace:
    addi $a0, $a0, 4
    addi $t0, $t0, 1

    j total_loop


adjust_aces:
    li $t3, 21
    ble $t1, $t3, total_done

    beq $t2, $zero, total_done

    # Change Ace from 11 to 1
    addi $t1, $t1, -10
    addi $t2, $t2, -1

    j adjust_aces


total_done:
    move $v0, $t1
    jr $ra


print_cards:
    move $t0, $a0
    move $t1, $a1
    li $t2, 0


print_cards_loop:
    beq $t2, $t1, print_cards_done

    lw $t3, 0($t0)

    # Print A instead of 11
    li $t4, 11
    beq $t3, $t4, print_ace

    move $a0, $t3
    li $v0, 1
    syscall

    j print_card_space


print_ace:
    li $v0, 4
    la $a0, aceText
    syscall


print_card_space:
    li $v0, 4
    la $a0, space
    syscall

    addi $t0, $t0, 4
    addi $t2, $t2, 1

    j print_cards_loop


print_cards_done:
    jr $ra


play_hand:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    li $s3, 1


player_hand_loop:
    li $v0, 4
    la $a0, handMessage
    syscall

    move $a0, $s2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, cardsMessage
    syscall

    move $a0, $s0
    move $a1, $s1
    jal print_cards

    move $a0, $s0
    move $a1, $s1
    jal calculate_total

    move $t0, $v0

    li $v0, 4
    la $a0, totalMessage
    syscall

    move $a0, $t0
    li $v0, 1
    syscall

    li $t1, 21
    beq $t0, $t1, player_has_21
    bgt $t0, $t1, player_busted

    # Double is available only before hitting
    beq $s3, $zero, ask_hit_or_stand

    li $v0, 4
    la $a0, choiceMessage
    syscall

    j read_player_choice


ask_hit_or_stand:
    li $v0, 4
    la $a0, hitStandMsg
    syscall


read_player_choice:
    jal read_choice

    move $t0, $v0

    li $t1, 104
    beq $t0, $t1, player_hits

    li $t1, 115
    beq $t0, $t1, player_stands

    li $t1, 100
    bne $t0, $t1, invalid_player_choice

    beq $s3, $zero, invalid_player_choice

    j player_doubles


invalid_player_choice:
    li $v0, 4
    la $a0, invalidChoice
    syscall

    j player_hand_loop


player_hits:
    jal get_card

    sll $t0, $s1, 2
    add $t0, $s0, $t0
    sw $v0, 0($t0)

    addi $s1, $s1, 1

    # Save correct hand count
    li $t0, 1
    beq $s2, $t0, save_hit_hand1

    sw $s1, hand2Count
    j hit_count_saved


save_hit_hand1:
    sw $s1, hand1Count


hit_count_saved:
    li $s3, 0
    jal draw_blackjack

    j player_hand_loop


player_doubles:
    # Double gives exactly one card
    jal get_card

    sll $t0, $s1, 2
    add $t0, $s0, $t0
    sw $v0, 0($t0)

    addi $s1, $s1, 1

    # Save correct hand count
    li $t0, 1
    beq $s2, $t0, save_double_hand1

    sw $s1, hand2Count
    j double_count_saved


save_double_hand1:
    sw $s1, hand1Count


double_count_saved:
    jal draw_blackjack

    # Show updated cards
    li $v0, 4
    la $a0, handMessage
    syscall

    move $a0, $s2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, cardsMessage
    syscall

    move $a0, $s0
    move $a1, $s1
    jal print_cards

    # Show updated total
    move $a0, $s0
    move $a1, $s1
    jal calculate_total

    move $t0, $v0

    li $v0, 4
    la $a0, totalMessage
    syscall

    move $a0, $t0
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, doubleMessage
    syscall

    li $v0, 1
    move $v1, $s1

    j play_hand_done


player_stands:
    li $v0, 0
    move $v1, $s1

    j play_hand_done


player_has_21:
    li $v0, 4
    la $a0, blackjackMsg
    syscall

    li $v0, 0
    move $v1, $s1

    j play_hand_done


player_busted:
    li $v0, 4
    la $a0, bustMessage
    syscall

    li $v0, 0
    move $v1, $s1


play_hand_done:
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


score_hand:
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

    # Normal points
    li $s1, 10

    # Double points
    beq $s2, $zero, score_points_ready
    li $s1, 20


score_points_ready:
    li $t0, 21

    bgt $s3, $t0, score_dealer_win

    lw $t1, dealerTotal
    bgt $t1, $t0, score_dealer_bust

    bgt $s3, $t1, score_player_win
    blt $s3, $t1, score_dealer_win

    li $v0, 4
    la $a0, tieMessage
    syscall

    li $v0, 0
    j score_hand_done


score_player_win:
    li $v0, 4
    la $a0, playerWinsMsg
    syscall

    move $v0, $s1
    j score_hand_done


score_dealer_bust:
    li $v0, 4
    la $a0, dealerBustMsg
    syscall

    move $v0, $s1
    j score_hand_done


score_dealer_win:
    li $v0, 4
    la $a0, dealerWinsMsg
    syscall

    sub $v0, $zero, $s1


score_hand_done:
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


# =========================================================
# BITMAP DISPLAY
#
# Unit Width: 8
# Unit Height: 8
# Display Width: 512
# Display Height: 256
# Base address: 0x10008000 ($gp)
# =========================================================

draw_blackjack:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    jal clear_blackjack_display

    # Draw dealer cards
    lw $s0, dealerCount
    li $s1, 0
    la $s3, dealerHand


draw_dealer_cards:
    beq $s1, $s0, start_player_cards

    # Card x position
    li $t0, 10
    mul $a0, $s1, $t0
    addi $a0, $a0, 2

    # Dealer y position
    li $a1, 1

    # Check for hidden card
    lw $t1, dealerHidden
    beq $t1, $zero, visible_dealer_card
    bne $s1, $zero, visible_dealer_card

    # Hidden card is red with no value
    li $a2, 0x00cc0000
    li $a3, -1
    jal draw_card

    j next_dealer_card


visible_dealer_card:
    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    li $a2, 0x00ffffff
    jal draw_card


next_dealer_card:
    addi $s1, $s1, 1
    j draw_dealer_cards


# Draw player hand 1
start_player_cards:
    lw $s0, hand1Count
    li $s1, 0
    la $s3, hand1

    lw $t0, splitUsed
    beq $t0, $zero, hand1_normal_row

    li $s2, 12
    j draw_hand1_loop


hand1_normal_row:
    li $s2, 22


draw_hand1_loop:
    beq $s1, $s0, check_second_hand

    li $t0, 10
    mul $a0, $s1, $t0
    addi $a0, $a0, 2

    move $a1, $s2
    li $a2, 0x00ffffff

    # Load actual card value
    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    jal draw_card

    addi $s1, $s1, 1
    j draw_hand1_loop


# Draw player hand 2
check_second_hand:
    lw $t0, splitUsed
    beq $t0, $zero, blackjack_drawing_done

    lw $s0, hand2Count
    li $s1, 0
    la $s3, hand2


draw_hand2_loop:
    beq $s1, $s0, blackjack_drawing_done

    li $t0, 10
    mul $a0, $s1, $t0
    addi $a0, $a0, 2

    li $a1, 22
    li $a2, 0x00dddddd

    # Load actual card value
    sll $t0, $s1, 2
    add $t0, $s3, $t0
    lw $a3, 0($t0)

    jal draw_card

    addi $s1, $s1, 1
    j draw_hand2_loop


blackjack_drawing_done:
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


# Fill display with green
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


# ---------------------------------------------------------
# Draw one card
#
# $a0 = x position
# $a1 = y position
# $a2 = card color
# $a3 = card value
# ---------------------------------------------------------

draw_card:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3

    li $t3, 0


draw_card_row:
    li $t4, 9
    beq $t3, $t4, card_rectangle_done

    li $t5, 0


draw_card_column:
    li $t4, 8
    beq $t5, $t4, next_card_row

    add $t6, $s0, $t5
    add $t7, $s1, $t3

    # Address = $gp + ((y * 64 + x) * 4)
    sll $t8, $t7, 6
    add $t8, $t8, $t6
    sll $t8, $t8, 2
    add $t8, $gp, $t8

    sw $s2, 0($t8)

    addi $t5, $t5, 1
    j draw_card_column


next_card_row:
    addi $t3, $t3, 1
    j draw_card_row


card_rectangle_done:
    # Hidden card has no value
    bltz $s3, draw_card_finished

    # Check for value 10
    li $t0, 10
    beq $s3, $t0, draw_card_ten

    # Draw centered number or A
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    move $a2, $s3
    jal draw_symbol

    j draw_card_finished


draw_card_ten:
    # Draw 1
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    li $a2, 1
    jal draw_symbol

    # Draw 0
    addi $a0, $s0, 4
    addi $a1, $s1, 2
    li $a2, 0
    jal draw_symbol


draw_card_finished:
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


# ---------------------------------------------------------
# Draw a 3-by-5 number or A
#
# $a0 = x position
# $a1 = y position
# $a2 = number or Ace value
# ---------------------------------------------------------

draw_symbol:
    move $t0, $a0
    move $t1, $a1

    # Ace uses shape number 10
    li $t2, 11
    bne $a2, $t2, symbol_number_ready

    li $a2, 10


symbol_number_ready:
    # Each symbol contains five rows
    li $t2, 5
    mul $t2, $a2, $t2

    la $t3, symbolRows
    add $t3, $t3, $t2

    li $t4, 0


symbol_row_loop:
    li $t5, 5
    beq $t4, $t5, symbol_done

    # Load current symbol row
    lbu $t6, 0($t3)
    li $t7, 0


symbol_column_loop:
    li $t5, 3
    beq $t7, $t5, next_symbol_row

    # Check current bit
    li $t8, 2
    sub $t8, $t8, $t7

    li $t9, 1
    sllv $t9, $t9, $t8

    and $t9, $t6, $t9
    beq $t9, $zero, skip_symbol_pixel

    # Calculate pixel coordinates
    add $t8, $t0, $t7
    add $t9, $t1, $t4

    # Address = $gp + ((y * 64 + x) * 4)
    sll $t9, $t9, 6
    add $t9, $t9, $t8
    sll $t9, $t9, 2
    add $t9, $gp, $t9

    # Draw number in black
    sw $zero, 0($t9)


skip_symbol_pixel:
    addi $t7, $t7, 1
    j symbol_column_loop


next_symbol_row:
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j symbol_row_loop


symbol_done:
    jr $ra